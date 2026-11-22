import Foundation

/// Рядок списку операцій, уже готовий для показу.
struct EntryRow: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String?
    let amountText: String
    let isNegative: Bool
    let date: Date
    /// Лише для витрат: дає змогу відкрити деталі. Для поповнень nil.
    let expenseID: UUID?

    init(topUp: CashTopUp, currency: Currency) {
        id = topUp.id
        title = topUp.source == .atm ? "🏧 Поповнення" : "➕ Коригування"
        subtitle = nil
        amountText = currency.format(topUp.signedAmount)
        isNegative = topUp.signedAmount < 0
        date = topUp.date
        expenseID = nil
    }

    init(expense: Expense, currency: Currency) {
        id = expense.id
        title = "\(expense.category.emoji) \(expense.category.title)"
        subtitle = expense.note
        amountText = currency.format(expense.signedAmount)
        isNegative = expense.signedAmount < 0
        date = expense.date
        expenseID = expense.id
    }
}
