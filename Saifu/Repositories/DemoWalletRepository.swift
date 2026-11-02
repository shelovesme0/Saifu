import Foundation

/// Репозиторій із даними демо-сценарію (гаманці JPY і UAH).
final class DemoWalletRepository: WalletRepository {
    private let inner: InMemoryWalletRepository

    /// За замовчуванням дані беремо з консольного сценарію, щоб не дублювати логіку.
    init(wallets: [CashWallet] = DemoScenario.run()) {
        inner = InMemoryWalletRepository(wallets: wallets)
    }

    func wallets() -> [CashWallet] {
        inner.wallets()
    }

    func save(_ wallet: CashWallet) {
        inner.save(wallet)
    }
}
