import Foundation

/// Зберігає гаманці лише в пам'яті; порожній, якщо не передати початкові.
final class InMemoryWalletRepository: WalletRepository {
    private var storage: [CashWallet]

    init(wallets: [CashWallet] = []) {
        storage = wallets
    }

    func wallets() -> [CashWallet] {
        storage
    }

    func save(_ wallet: CashWallet) {
        if let index = storage.firstIndex(where: { $0.name == wallet.name }) {
            storage[index] = wallet
        } else {
            storage.append(wallet)
        }
    }
}
