import Foundation

enum WalletError: Error {
    /// Сума має бути невід'ємною (для витрат і поповнень — додатною).
    case negativeAmount
    /// Рядок суми не вдалося розпізнати як число.
    case invalidAmount
    /// Категорію витрати не задано.
    case missingCategory
}
