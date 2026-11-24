import Foundation

/// Імена файлів копій. Імена з датою сортуються так само, як час створення.
nonisolated enum BackupFileName {
    /// Актуальна копія, перезаписується після кожної зміни.
    static let latest = "Saifu-latest.json"
    /// Щоденні знімки `Saifu-backup-2026-11-24.json` і ручний експорт `Saifu-backup-2026-11-24-1805.json`.
    static let autoPrefix = "Saifu-backup-"
    static let preImportPrefix = "Saifu-before-import-"
    static let fileExtension = "json"

    /// Щоденний знімок: `Saifu-backup-2026-11-24.json`.
    static func daily(date: Date) -> String {
        autoPrefix + format(date, "yyyy-MM-dd") + "." + fileExtension
    }

    /// `Saifu-backup-` + `yyyy-MM-dd` (10 символів) + `.json`.
    static func isDailySnapshot(_ name: String) -> Bool {
        guard name.hasPrefix(autoPrefix), name.hasSuffix("." + fileExtension) else { return false }
        let datePart = name.dropFirst(autoPrefix.count).dropLast(fileExtension.count + 1)
        return datePart.count == 10 && datePart.allSatisfy { $0.isNumber || $0 == "-" }
    }

    /// Ім'я без розширення (для `.fileExporter`, який додає розширення сам).
    static func baseName(prefix: String, date: Date) -> String {
        prefix + format(date, "yyyy-MM-dd-HHmm")
    }

    private static func format(_ date: Date, _ pattern: String) -> String {
        let formatter = DateFormatter()
        // POSIX: цифри й формат не залежать від мови та 12/24-годинного часу на пристрої
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    static func fileName(prefix: String, date: Date) -> String {
        baseName(prefix: prefix, date: date) + "." + fileExtension
    }
}

/// Контейнер застосунку (зокрема «Файли → На iPhone → Saifu») видаляється разом із застосунком,
/// тому копії там не переживуть видалення.
enum AppContainer {
    /// Чи лежить `url` усередині домашньої директорії застосунку.
    static func contains(_ url: URL, home: URL = URL(fileURLWithPath: NSHomeDirectory())) -> Bool {
        let path = normalizedPath(url)
        let homePath = normalizedPath(home)
        return path == homePath || path.hasPrefix(homePath + "/")
    }

    /// Пікер може повернути `/private/var/...`, а домашня директорія — `/var/...`: це той самий шлях.
    private static func normalizedPath(_ url: URL) -> String {
        var path = url.standardizedFileURL.resolvingSymlinksInPath().path
        if path.hasPrefix("/private/") {
            path.removeFirst("/private".count)
        }
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }
}

/// Папка для автоматичних копій, яку один раз обрав користувач.
/// nonisolated і Sendable: автокопія пишеться поза головним потоком, щоб не блокувати UI.
nonisolated protocol BackupFolderAccess: Sendable {
    /// Чи обрано папку.
    var isConfigured: Bool { get }
    /// Назва папки для показу; nil, якщо не обрано.
    var folderName: String? { get }
    /// Запам'ятовує папку з `.fileImporter`. Кидає `folderUnavailable`, якщо доступу немає.
    func setFolder(_ url: URL) throws
    func clear()
    /// Записує файл у папку (наявний з тим самим іменем замінюється). Кидає `folderUnavailable` або `writeFailed`.
    func write(_ data: Data, fileName: String) throws
    /// Автокопія: перезаписує `Saifu-latest.json`; якщо сьогоднішнього знімка ще немає — створює його
    /// і лишає `keepDaily` найновіших. Кидає `folderUnavailable` або `writeFailed`.
    func saveAutoBackup(_ data: Data, date: Date, keepDaily: Int) throws
}

/// Зберігає доступ до папки як security-scoped bookmark у UserDefaults.
/// Bookmark переживає перезапуск застосунку; на iOS для цього не потрібні entitlements.
/// `@unchecked Sendable`: властивості лише `let`, а UserDefaults і FileManager потокобезпечні (документація Apple).
nonisolated final class BookmarkBackupFolder: BackupFolderAccess, @unchecked Sendable {
    enum Keys {
        static let bookmark = "backupFolderBookmark"
        static let folderName = "backupFolderName"
    }

    private let defaults: UserDefaults
    private let fileManager: FileManager

    init(defaults: UserDefaults, fileManager: FileManager = .default) {
        self.defaults = defaults
        self.fileManager = fileManager
    }

    var isConfigured: Bool {
        defaults.data(forKey: Keys.bookmark) != nil
    }

    var folderName: String? {
        isConfigured ? defaults.string(forKey: Keys.folderName) : nil
    }

    func setFolder(_ url: URL) throws {
        // URL з пікера доступний лише між start/stop; bookmark треба створити саме в цей час
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let bookmark = try? url.bookmarkData() else { throw BackupError.folderUnavailable }
        defaults.set(bookmark, forKey: Keys.bookmark)
        defaults.set(url.lastPathComponent, forKey: Keys.folderName)
    }

    func clear() {
        defaults.removeObject(forKey: Keys.bookmark)
        defaults.removeObject(forKey: Keys.folderName)
    }

    func write(_ data: Data, fileName: String) throws {
        try withFolder { folder in
            do {
                try data.write(to: folder.appendingPathComponent(fileName), options: .atomic)
            } catch {
                throw BackupError.writeFailed
            }
        }
    }

    func saveAutoBackup(_ data: Data, date: Date, keepDaily: Int) throws {
        try withFolder { folder in
            do {
                // .atomic: спершу тимчасовий файл, потім заміна — обірваний запис не зіпсує попередню копію
                try data.write(to: folder.appendingPathComponent(BackupFileName.latest), options: .atomic)
                let daily = folder.appendingPathComponent(BackupFileName.daily(date: date))
                // Знімок — не частіше одного на день: перша зміна дня його створює
                guard !fileManager.fileExists(atPath: daily.path) else { return }
                try data.write(to: daily, options: .atomic)
            } catch {
                throw BackupError.writeFailed
            }
            removeOldDailySnapshots(in: folder, keep: keepDaily)
        }
    }

    /// Лишає `keep` найновіших щоденних знімків, решту видаляє.
    /// Ручні експорти (`…-HHmm.json`), latest і файли інших застосунків не чіпаються.
    private func removeOldDailySnapshots(in folder: URL, keep: Int) {
        let names = (try? fileManager.contentsOfDirectory(atPath: folder.path)) ?? []
        let backups = names
            .filter(BackupFileName.isDailySnapshot)
            .sorted(by: >) // новіші — першими
        for name in backups.dropFirst(keep) {
            try? fileManager.removeItem(at: folder.appendingPathComponent(name))
        }
    }

    /// Відкриває доступ до папки на час `body`. Будь-яка проблема з доступом — `folderUnavailable`.
    private func withFolder(_ body: (URL) throws -> Void) throws {
        guard let bookmark = defaults.data(forKey: Keys.bookmark) else { throw BackupError.folderUnavailable }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
            throw BackupError.folderUnavailable
        }
        // false означає, що URL не потребує security scope (наприклад, звичайна папка), а не відмову:
        // чи є доступ, покаже перевірка нижче й сам запис
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        // Папку могли видалити, хоча bookmark ще розпізнається
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw BackupError.folderUnavailable
        }
        // Папку перемістили чи перейменували — оновлюємо bookmark, поки є доступ
        if isStale, let fresh = try? url.bookmarkData() {
            defaults.set(fresh, forKey: Keys.bookmark)
            defaults.set(url.lastPathComponent, forKey: Keys.folderName)
        }
        try body(url)
    }
}
