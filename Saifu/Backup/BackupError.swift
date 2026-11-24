import Foundation

/// Помилки резервного копіювання.
enum BackupError: Error, Equatable {
    /// Файл створено новішою версією застосунку (невідома версія формату).
    case unsupportedVersion(Int)
    /// Файл не є копією Saifu або пошкоджений.
    case corrupted
    /// Файл не вдалося прочитати.
    case readFailed
    /// Файл не вдалося записати.
    case writeFailed
    /// Немає доступу до вибраної папки (видалена, перейменована або доступ відкликано).
    case folderUnavailable
    /// Не вдалося зберегти копію поточних даних перед імпортом, тому імпорт скасовано.
    case preImportCopyFailed
}

extension BackupError {
    /// Текст для UI.
    var userMessage: String {
        switch self {
        case .unsupportedVersion(let version):
            return "Копію створено новішою версією застосунку (формат \(version)). Оновіть Saifu і спробуйте ще раз"
        case .corrupted:
            return "Файл пошкоджений або не є резервною копією Saifu"
        case .readFailed:
            return "Не вдалося прочитати файл"
        case .writeFailed:
            return "Не вдалося записати файл копії"
        case .folderUnavailable:
            return "Немає доступу до папки резервних копій"
        case .preImportCopyFailed:
            return "Не вдалося зберегти копію поточних даних, тому імпорт скасовано. Дані не змінено"
        }
    }

    /// Текст для будь-якої помилки під час копіювання.
    static func message(for error: any Error) -> String {
        if let backupError = error as? BackupError {
            return backupError.userMessage
        }
        if let repositoryError = error as? RepositoryError {
            return repositoryError.userMessage
        }
        return "Щось пішло не так. Спробуйте ще раз"
    }
}
