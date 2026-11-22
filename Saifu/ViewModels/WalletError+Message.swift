import Foundation

/// Тексти помилок для UI. Окремо від моделі, щоб домен не знав про презентацію.
extension WalletError {
    var userMessage: String {
        switch self {
        case .negativeAmount: return "Сума має бути більшою за нуль"
        case .invalidAmount: return "Некоректна сума"
        case .missingCategory: return "Оберіть категорію"
        case .expenseNotFound: return "Витрату не знайдено"
        case .walletNotEmpty: return "Валюту можна змінити лише в гаманці без записів"
        }
    }

    /// Текст для будь-якої помилки: WalletError має свій, інші — `fallback`.
    static func message(for error: any Error, fallback: String) -> String {
        (error as? WalletError)?.userMessage ?? fallback
    }
}
