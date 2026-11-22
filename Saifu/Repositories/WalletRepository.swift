import Foundation

/// Джерело гаманців для ViewModel. Реалізації можна підміняти (пам'ять, демо, пізніше диск).
protocol WalletRepository {
    func wallets() -> [CashWallet]
    /// Зберігає новий гаманець або оновлює наявний (за `id`).
    func save(_ wallet: CashWallet)
    /// Видаляє гаманець; невідомий `id` ігнорується.
    func remove(id: CashWallet.ID)
    /// Змінює порядок гаманців (як у List.onMove); порядок бачать усі екрани.
    func move(fromOffsets source: IndexSet, toOffset destination: Int)
}

extension WalletRepository {
    /// Пошук гаманця за id для екранів, що отримують лише ідентифікатор.
    func wallet(id: CashWallet.ID) -> CashWallet? {
        wallets().first { $0.id == id }
    }
}
