import Foundation

/// Помилки сховища гаманців.
enum RepositoryError: Error {
    /// Зміни не вдалося записати на пристрій.
    case saveFailed
}
