import Foundation

/// Рядок списку операцій, уже готовий для показу.
struct EntryRow: Identifiable, Equatable {
    let id: UUID
    /// Нотатка, а якщо її немає — назва категорії.
    let title: String
    /// Категорія дрібним шрифтом.
    let subtitle: String?
    let amountText: String
    let isNegative: Bool
    let date: Date
    /// Категорія для іконки; nil для поповнень.
    let category: ExpenseCategory?
    /// Лише для витрат: дає змогу відкрити деталі. Для поповнень nil.
    let expenseID: UUID?

    /// SF Symbol рядка.
    var symbolName: String {
        category?.symbolName ?? "arrow.down.circle"
    }

    init(topUp: CashTopUp, currency: Currency) {
        id = topUp.id
        title = topUp.source == .atm ? "Поповнення" : "Коригування"
        subtitle = nil
        amountText = currency.format(topUp.signedAmount)
        isNegative = topUp.signedAmount < 0
        date = topUp.date
        category = nil
        expenseID = nil
    }

    init(expense: Expense, currency: Currency) {
        id = expense.id
        title = expense.note ?? expense.category.title
        subtitle = expense.note == nil ? nil : expense.category.title
        amountText = currency.format(expense.signedAmount)
        isNegative = expense.signedAmount < 0
        date = expense.date
        category = expense.category
        expenseID = expense.id
    }
}
