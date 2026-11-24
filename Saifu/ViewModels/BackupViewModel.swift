import Foundation
import Observation

/// Резервна копія в налаштуваннях: автоматична копія в обрану папку, ручні експорт та імпорт.
/// Автокопія: `Saifu-latest.json` перезаписується через ~3 с після останньої зміни даних (серія змін — один запис),
/// при першій зміні дня створюється щоденний знімок. Запис — лише якщо відбиток даних змінився.
@MainActor
@Observable
final class BackupViewModel {
    enum Keys {
        static let autoBackupEnabled = "autoBackupEnabled"
        /// Час останнього запису `Saifu-latest.json` — для показу.
        static let lastBackupDate = "lastBackupDate"
        /// Відбиток даних останньої автоматичної копії: якщо не змінився, нова копія не потрібна.
        static let lastAutoBackupFingerprint = "lastAutoBackupFingerprint"
    }

    /// Скільки щоденних знімків зберігати в папці.
    static let keepDailyCount = 7

    /// Що вибирається в системному пікері (на екрані один `.fileImporter`).
    enum PickerMode {
        case folder, backupFile
    }

    struct Message: Equatable {
        let text: String
        let isError: Bool
    }

    private let service: any BackupService
    private let folder: any BackupFolderAccess
    private let defaults: UserDefaults
    /// Куди зберігати копію перед імпортом, якщо папку автокопії не обрано (Documents застосунку).
    private let localDirectory: URL
    /// Після імпорту: оновити екрани, що тримають старі екземпляри гаманців.
    private let onDataReplaced: () -> Void

    private(set) var isAutoBackupEnabled: Bool
    /// Доступ до папки втрачено: показується попередження і «Вибрати папку знову».
    private(set) var isFolderUnavailable = false
    private(set) var lastBackupDate: Date?
    private(set) var message: Message?

    var isPickerPresented = false
    private(set) var pickerMode: PickerMode = .folder
    var isExporterPresented = false
    private(set) var exportDocument: BackupDocument?
    private(set) var exportFileName = ""
    /// Перевірені гаманці з файлу, що чекають підтвердження заміни.
    private var pendingWallets: [CashWallet]?

    /// Пауза після останньої зміни перед записом.
    private let debounceDelay: Duration
    /// Відкладений запис; нова зміна скасовує його й ставить заново.
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    /// Останній запущений запис: наступний чекає на нього, тож записи йдуть строго по черзі.
    @ObservationIgnored private var currentWrite: Task<BackupError?, Never>?
    /// Є зміни, які ще не записано (дебаунс не спрацював).
    @ObservationIgnored private(set) var hasPendingChanges = false

    init(service: any BackupService,
         folder: any BackupFolderAccess,
         defaults: UserDefaults,
         localDirectory: URL,
         debounceDelay: Duration = .seconds(3),
         onDataReplaced: @escaping () -> Void) {
        self.service = service
        self.folder = folder
        self.defaults = defaults
        self.localDirectory = localDirectory
        self.debounceDelay = debounceDelay
        self.onDataReplaced = onDataReplaced
        isAutoBackupEnabled = defaults.bool(forKey: Keys.autoBackupEnabled) && folder.isConfigured
        lastBackupDate = defaults.object(forKey: Keys.lastBackupDate) as? Date
    }

    // MARK: - Стан для екрана

    var folderName: String? {
        folder.folderName
    }

    var lastBackupText: String {
        guard let lastBackupDate else { return "Копій ще не створювалося" }
        return "Остання копія: " + lastBackupDate.formatted(
            Date.FormatStyle(date: .numeric, time: .shortened).locale(Locale(identifier: "uk_UA"))
        )
    }

    var isConfirmingImport: Bool {
        get { pendingWallets != nil }
        set { if !newValue { pendingWallets = nil } }
    }

    // MARK: - Автоматична копія

    /// Увімкнення відкриває вибір папки; тумблер лишається увімкненим, лише якщо папку обрано.
    func setAutoBackup(_ enabled: Bool) {
        message = nil
        guard enabled else {
            isAutoBackupEnabled = false
            isFolderUnavailable = false
            debounceTask?.cancel()
            debounceTask = nil
            hasPendingChanges = false
            defaults.set(false, forKey: Keys.autoBackupEnabled)
            folder.clear()
            return
        }
        isAutoBackupEnabled = true
        presentPicker(.folder)
    }

    /// «Вибрати папку знову» після втрати доступу.
    func chooseFolderAgainTapped() {
        message = nil
        presentPicker(.folder)
    }

    /// Дані змінилися (викликає `ChangeNotifyingWalletRepository`): запис через `debounceDelay`.
    func dataChanged() {
        guard isAutoBackupEnabled else { return }
        hasPendingChanges = true
        debounceTask?.cancel()
        debounceTask = Task { [weak self, debounceDelay] in
            try? await Task.sleep(for: debounceDelay)
            guard !Task.isCancelled, let self else { return }
            debounceTask = nil
            _ = await startWrite().value
        }
    }

    /// Вихід у фон: незаписані зміни пишуться одразу, не чекаючи дебаунсу.
    /// Викликається всередині фонового завдання (`ScreenFactory.appDidEnterBackground`).
    func appDidEnterBackground() async {
        guard hasPendingChanges else {
            // Можливо, саме йде запис — дочекаємося, щоб iOS не призупинила його посередині
            _ = await currentWrite?.value
            return
        }
        debounceTask?.cancel()
        debounceTask = nil
        _ = await startWrite().value
    }

    /// Ставить запис у чергу за попереднім.
    private func startWrite() -> Task<BackupError?, Never> {
        let previous = currentWrite
        let task = Task { [weak self] () -> BackupError? in
            _ = await previous?.value
            return await self?.writeIfChanged()
        }
        currentWrite = task
        return task
    }

    /// Записує копію, якщо дані змінилися з минулого запису. Повертає помилку для повідомлення.
    private func writeIfChanged() async -> BackupError? {
        guard isAutoBackupEnabled else { return nil }
        hasPendingChanges = false
        // JSON готується на головному акторі (дані живуть там), а файлові операції — у фоні
        guard let fingerprint = try? service.fingerprint(),
              fingerprint != defaults.string(forKey: Keys.lastAutoBackupFingerprint) else { return nil }
        guard let data = try? service.exportData() else { return .writeFailed }
        let folder = folder
        let now = Date()
        let keep = Self.keepDailyCount
        let result = await Task.detached(priority: .utility) {
            Result { try folder.saveAutoBackup(data, date: now, keepDaily: keep) }
        }.value

        switch result {
        case .success:
            isFolderUnavailable = false
            defaults.set(fingerprint, forKey: Keys.lastAutoBackupFingerprint)
            recordBackup(at: now)
            return nil
        case .failure(let error):
            let backupError = error as? BackupError ?? .writeFailed
            if backupError == .folderUnavailable {
                isFolderUnavailable = true
            }
            return backupError
        }
    }

    private func folderPicked(_ url: URL) {
        // Копії в контейнері застосунку зникнуть разом із ним — таку папку не приймаємо
        guard !AppContainer.contains(url) else {
            message = Message(text: BackupError.folderInsideApp.userMessage, isError: true)
            revertToggleIfNoFolder()
            return
        }
        do {
            try folder.setFolder(url)
            isFolderUnavailable = false
            isAutoBackupEnabled = true
            defaults.set(true, forKey: Keys.autoBackupEnabled)
            // Нова папка порожня: відбиток скидаємо, щоб перша копія записалася навіть без змін у даних
            defaults.removeObject(forKey: Keys.lastAutoBackupFingerprint)
        } catch {
            message = Message(text: BackupError.message(for: error), isError: true)
            return
        }
        // Перша копія одразу: заодно перевіряємо, що в папку можна писати
        let name = url.lastPathComponent
        Task {
            if let error = await startWrite().value {
                message = Message(text: error.userMessage, isError: true)
            } else {
                message = Message(text: "Копію збережено в «\(name)»", isError: false)
            }
        }
    }

    // MARK: - Експорт

    func exportTapped() {
        message = nil
        do {
            exportDocument = BackupDocument(data: try service.exportData())
            exportFileName = BackupFileName.baseName(prefix: BackupFileName.autoPrefix, date: Date())
            isExporterPresented = true
        } catch {
            message = Message(text: BackupError.message(for: error), isError: true)
        }
    }

    func exportFinished(_ result: Result<URL, any Error>) {
        exportDocument = nil
        switch result {
        case .success(let url):
            if AppContainer.contains(url) {
                message = Message(text: "Копію експортовано, але " + BackupError.folderInsideApp.userMessage.lowercasedFirst,
                                  isError: true)
            } else {
                message = Message(text: "Копію експортовано", isError: false)
            }
        case .failure(let error):
            // Скасування користувачем — не помилка
            if (error as? CocoaError)?.code == .userCancelled { return }
            message = Message(text: BackupError.writeFailed.userMessage, isError: true)
        }
    }

    // MARK: - Імпорт

    func importTapped() {
        message = nil
        presentPicker(.backupFile)
    }

    /// Результат системного пікера (і для папки, і для файлу).
    func pickerFinished(_ result: Result<URL, any Error>) {
        switch (pickerMode, result) {
        case (.folder, .success(let url)):
            folderPicked(url)
        case (.folder, .failure):
            revertToggleIfNoFolder()
        case (.backupFile, .success(let url)):
            fileToImportPicked(url)
        case (.backupFile, .failure):
            break
        }
    }

    /// Файл перевіряється одразу: пошкоджений або невідомої версії не доходить до підтвердження.
    private func fileToImportPicked(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            guard let data = try? Data(contentsOf: url) else { throw BackupError.readFailed }
            pendingWallets = try service.validate(data)
        } catch {
            message = Message(text: BackupError.message(for: error), isError: true)
        }
    }

    /// «Замінити» в підтвердженні: спершу копія поточних даних, потім заміна.
    func confirmImport() {
        guard let wallets = pendingWallets else { return }
        pendingWallets = nil
        do {
            let savedTo = try savePreImportCopy()
            try service.restore(wallets)
            onDataReplaced()
            message = Message(text: "Дані відновлено. Попередні збережено в «\(savedTo)»", isError: false)
        } catch {
            message = Message(text: BackupError.message(for: error), isError: true)
        }
    }

    /// Копія поточних даних перед заміною: у папку автокопії, інакше в Documents застосунку.
    /// Повертає назву місця для повідомлення.
    private func savePreImportCopy() throws -> String {
        let data: Data
        do {
            data = try service.exportData()
        } catch {
            throw BackupError.preImportCopyFailed
        }
        let fileName = BackupFileName.fileName(prefix: BackupFileName.preImportPrefix, date: Date())
        if isAutoBackupEnabled, let name = folder.folderName, (try? folder.write(data, fileName: fileName)) != nil {
            return name
        }
        do {
            try data.write(to: localDirectory.appendingPathComponent(fileName), options: .atomic)
            return "Файли → На iPhone → Saifu"
        } catch {
            throw BackupError.preImportCopyFailed
        }
    }

    // MARK: - Допоміжне

    /// Папку не обрано (пікер закрито чи папку відхилено): без папки автокопія не вмикається.
    /// Якщо раніше обрана папка вже працює, вона лишається.
    private func revertToggleIfNoFolder() {
        if !folder.isConfigured || !defaults.bool(forKey: Keys.autoBackupEnabled) {
            isAutoBackupEnabled = false
        }
    }

    private func presentPicker(_ mode: PickerMode) {
        pickerMode = mode
        isPickerPresented = true
    }

    private func recordBackup(at date: Date) {
        lastBackupDate = date
        defaults.set(date, forKey: Keys.lastBackupDate)
    }
}

private extension String {
    /// "Ця папка…" → "ця папка…" для вставки всередину речення.
    var lowercasedFirst: String {
        prefix(1).lowercased() + dropFirst()
    }
}
