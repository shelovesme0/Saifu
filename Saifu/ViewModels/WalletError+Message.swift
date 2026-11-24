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

    /// Текст для будь-якої помилки: WalletError і RepositoryError мають свій, інші — `fallback`.
    static func message(for error: any Error, fallback: String) -> String {
        if let walletError = error as? WalletError {
            return walletError.userMessage
        }
        if let repositoryError = error as? RepositoryError {
            return repositoryError.userMessage
        }
        return fallback
    }
}

extension RepositoryError {
    var userMessage: String {
        switch self {
        case .saveFailed: return "Не вдалося зберегти зміни на пристрої. Спробуйте ще раз"
        }
    }
}
