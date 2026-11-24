import Foundation
import Observation

/// Резервна копія в налаштуваннях: автоматична копія в обрану папку, ручні експорт та імпорт.
@MainActor
@Observable
final class BackupViewModel {
    enum Keys {
        static let autoBackupEnabled = "autoBackupEnabled"
        /// Остання будь-яка копія (автоматична чи експорт) — для показу.
        static let lastBackupDate = "lastBackupDate"
        /// Остання автоматична копія — для обмеження «не частіше разу на годину».
        static let lastAutoBackupDate = "lastAutoBackupDate"
        /// Відбиток даних останньої автоматичної копії: якщо не змінився, нова копія не потрібна.
        static let lastAutoBackupFingerprint = "lastAutoBackupFingerprint"
    }

    /// Скільки автоматичних копій зберігати в папці.
    static let keepCount = 7
    /// Мінімальний проміжок між автоматичними копіями.
    static let minInterval: TimeInterval = 60 * 60

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

    init(service: any BackupService,
         folder: any BackupFolderAccess,
         defaults: UserDefaults,
         localDirectory: URL,
         onDataReplaced: @escaping () -> Void) {
        self.service = service
        self.folder = folder
        self.defaults = defaults
        self.localDirectory = localDirectory
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

    /// Вихід у фон: копія, якщо є незбережені зміни і від минулої пройшло не менше години.
    func appDidEnterBackground() {
        guard isAutoBackupEnabled else { return }
        if let last = defaults.object(forKey: Keys.lastAutoBackupDate) as? Date,
           Date().timeIntervalSince(last) < Self.minInterval {
            return
        }
        guard let fingerprint = try? service.fingerprint(),
              fingerprint != defaults.string(forKey: Keys.lastAutoBackupFingerprint) else { return }
        try? writeAutoBackup(fingerprint: fingerprint)
    }

    private func folderPicked(_ url: URL) {
        do {
            try folder.setFolder(url)
            isFolderUnavailable = false
            isAutoBackupEnabled = true
            defaults.set(true, forKey: Keys.autoBackupEnabled)
            // Перша копія одразу: заодно перевіряємо, що в папку можна писати
            try writeAutoBackup(fingerprint: service.fingerprint())
            message = Message(text: "Копію збережено в «\(url.lastPathComponent)»", isError: false)
        } catch {
            message = Message(text: BackupError.message(for: error), isError: true)
        }
    }

    private func writeAutoBackup(fingerprint: String) throws {
        do {
            let now = Date()
            try folder.write(service.exportData(),
                             fileName: BackupFileName.fileName(prefix: BackupFileName.autoPrefix, date: now))
            try? folder.removeOldFiles(prefix: BackupFileName.autoPrefix, keep: Self.keepCount)
            isFolderUnavailable = false
            defaults.set(now, forKey: Keys.lastAutoBackupDate)
            defaults.set(fingerprint, forKey: Keys.lastAutoBackupFingerprint)
            recordBackup(at: now)
        } catch BackupError.folderUnavailable {
            isFolderUnavailable = true
            throw BackupError.folderUnavailable
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
        case .success:
            recordBackup(at: Date())
            message = Message(text: "Копію експортовано", isError: false)
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
            // Пікер закрито без вибору: без папки автокопія не вмикається
            if !folder.isConfigured || !defaults.bool(forKey: Keys.autoBackupEnabled) {
                isAutoBackupEnabled = false
            }
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

    private func presentPicker(_ mode: PickerMode) {
        pickerMode = mode
        isPickerPresented = true
    }

    private func recordBackup(at date: Date) {
        lastBackupDate = date
        defaults.set(date, forKey: Keys.lastBackupDate)
    }
}
