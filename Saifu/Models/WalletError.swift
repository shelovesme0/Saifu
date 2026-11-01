import Foundation

enum WalletError: Error {
    /// Сума має бути невід'ємною (для витрат і поповнень — додатною).
    case negativeAmount
}
