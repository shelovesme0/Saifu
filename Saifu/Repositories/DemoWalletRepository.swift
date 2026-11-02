import Foundation

/// Репозиторій із даними демо-сценарію (гаманці JPY і UAH).
final class DemoWalletRepository: WalletRepository {
    private let inner: InMemoryWalletRepository

    init() {
        // Дані беремо з консольного сценарію, щоб не дублювати логіку
        inner = InMemoryWalletRepository(wallets: DemoScenario.run())
    }

    func wallets() -> [CashWallet] {
        inner.wallets()
    }

    func save(_ wallet: CashWallet) {
        inner.save(wallet)
    }
}
