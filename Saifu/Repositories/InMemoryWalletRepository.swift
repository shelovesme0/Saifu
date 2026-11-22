import Foundation
import Observation

/// Зберігає гаманці лише в пам'яті; порожній, якщо не передати початкові.
/// @Observable: екрани, що читають `wallets()`, оновлюються після додавання чи видалення гаманця.
@Observable
final class InMemoryWalletRepository: WalletRepository {
    private var storage: [CashWallet]

    init(wallets: [CashWallet] = []) {
        storage = wallets
    }

    func wallets() -> [CashWallet] {
        storage
    }

    func save(_ wallet: CashWallet) {
        if let index = storage.firstIndex(where: { $0.id == wallet.id }) {
            storage[index] = wallet
        } else {
            storage.append(wallet)
        }
    }

    func remove(id: CashWallet.ID) {
        storage.removeAll { $0.id == id }
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.map { storage[$0] }
        // Індекс вставки зсувається на кількість елементів, що стояли перед ним
        let insertAt = destination - source.filter { $0 < destination }.count
        for index in source.sorted(by: >) {
            storage.remove(at: index)
        }
        storage.insert(contentsOf: moving, at: min(max(insertAt, 0), storage.count))
    }
}
