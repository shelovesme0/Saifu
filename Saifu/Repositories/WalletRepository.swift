import Foundation

/// Джерело гаманців для ViewModel. Реалізації можна підміняти (пам'ять, демо, пізніше диск).
protocol WalletRepository {
    func wallets() -> [CashWallet]
    /// Зберігає новий гаманець або оновлює наявний (за `name`).
    func save(_ wallet: CashWallet)
}
