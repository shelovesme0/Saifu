import Foundation

/// Стан завантаження даних із сервера для показу в UI.
enum LoadState: Equatable {
    /// Ще не завантажували.
    case idle
    case loading
    case loaded
    /// Сервер відповів, але даних немає.
    case empty
    /// Повідомлення вже зрозуміле користувачу.
    case failed(String)
}
