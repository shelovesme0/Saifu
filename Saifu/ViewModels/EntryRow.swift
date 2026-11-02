import Foundation

/// Рядок списку операцій, уже готовий для показу.
struct EntryRow: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let amountText: String
    let isNegative: Bool

    init(topUp: CashTopUp, currency: Currency) {
        id = topUp.id
        title = topUp.source == .atm ? "🏧 Поповнення" : "➕ Коригування"
        subtitle = nil
        amountText = currency.format(topUp.signedAmount)
        isNegative = topUp.signedAmount < 0
    }

    init(expense: Expense, currency: Currency) {
        id = expense.id
        title = "\(expense.category.emoji) \(expense.category.title)"
        subtitle = expense.note
        amountText = currency.format(expense.signedAmount)
        isNegative = expense.signedAmount < 0
    }
}
