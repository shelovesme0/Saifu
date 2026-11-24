import Foundation

/// Імена файлів копій: `Saifu-backup-2026-11-24-1805.json`. Імена сортуються так само, як час створення.
enum BackupFileName {
    static let autoPrefix = "Saifu-backup-"
    static let preImportPrefix = "Saifu-before-import-"
    static let fileExtension = "json"

    /// Ім'я без розширення (для `.fileExporter`, який додає розширення сам).
    static func baseName(prefix: String, date: Date) -> String {
        let formatter = DateFormatter()
        // POSIX: цифри й формат не залежать від мови та 12/24-годинного часу на пристрої
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return prefix + formatter.string(from: date)
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
protocol BackupFolderAccess {
    /// Чи обрано папку.
    var isConfigured: Bool { get }
    /// Назва папки для показу; nil, якщо не обрано.
    var folderName: String? { get }
    /// Запам'ятовує папку з `.fileImporter`. Кидає `folderUnavailable`, якщо доступу немає.
    func setFolder(_ url: URL) throws
    func clear()
    /// Записує файл у папку (наявний з тим самим іменем замінюється). Кидає `folderUnavailable` або `writeFailed`.
    func write(_ data: Data, fileName: String) throws
    /// Лишає `keep` найновіших файлів з іменем на `prefix`, решту видаляє.
    func removeOldFiles(prefix: String, keep: Int) throws
}

/// Зберігає доступ до папки як security-scoped bookmark у UserDefaults.
/// Bookmark переживає перезапуск застосунку; на iOS для цього не потрібні entitlements.
final class BookmarkBackupFolder: BackupFolderAccess {
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

    func removeOldFiles(prefix: String, keep: Int) throws {
        try withFolder { folder in
            let names = (try? fileManager.contentsOfDirectory(atPath: folder.path)) ?? []
            let backups = names
                .filter { $0.hasPrefix(prefix) && $0.hasSuffix("." + BackupFileName.fileExtension) }
                .sorted(by: >) // новіші — першими
            for name in backups.dropFirst(keep) {
                try? fileManager.removeItem(at: folder.appendingPathComponent(name))
            }
        }
    }

    /// Відкриває доступ до папки на час `body`. Будь-яка проблема з доступом — `folderUnavailable`.
    private func withFolder(_ body: (URL) throws -> Void) throws {
        guard let bookmark = defaults.data(forKey: Keys.bookmark) else { throw BackupError.folderUnavailable }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale),
              url.startAccessingSecurityScopedResource() else {
            throw BackupError.folderUnavailable
        }
        defer { url.stopAccessingSecurityScopedResource() }

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
