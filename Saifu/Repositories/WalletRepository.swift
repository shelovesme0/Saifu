import Foundation

/// Джерело гаманців для ViewModel. Реалізації можна підміняти (диск, пам'ять, демо).
protocol WalletRepository {
    func wallets() -> [CashWallet]
    /// Зберігає новий гаманець або оновлює наявний (за `id`). Кидає `RepositoryError`, якщо запис не вдався.
    func save(_ wallet: CashWallet) throws
    /// Видаляє гаманець; невідомий `id` ігнорується.
    func remove(id: CashWallet.ID) throws
    /// Змінює порядок гаманців (як у List.onMove); порядок бачать усі екрани.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) throws
    /// Замінює всі гаманці (імпорт резервної копії); порядок — як у масиві.
    /// Якщо запис не вдався, кидає `RepositoryError`, а попередні дані лишаються без змін.
    func replaceAll(with wallets: [CashWallet]) throws
}

extension WalletRepository {
    /// Пошук гаманця за id для екранів, що отримують лише ідентифікатор.
    func wallet(id: CashWallet.ID) -> CashWallet? {
        wallets().first { $0.id == id }
    }
}
