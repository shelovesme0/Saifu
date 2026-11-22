import Foundation

/// Збирає `Expense` з рядка суми, категорії, нотатки та дати. Кожен метод повертає копію.
/// Розбір суми — у `Currency.parseMinor`.
struct ExpenseBuilder {
    private let currency: Currency
    private var id = UUID()
    private var amountText = ""
    private var category: ExpenseCategory?
    private var note: String?
    private var date = Date()
    private var receiptID: String?

    init(currency: Currency) {
        self.currency = currency
    }

    func amount(_ text: String) -> ExpenseBuilder {
        var copy = self
        copy.amountText = text
        return copy
    }

    func category(_ category: ExpenseCategory?) -> ExpenseBuilder {
        var copy = self
        copy.category = category
        return copy
    }

    func note(_ note: String?) -> ExpenseBuilder {
        var copy = self
        copy.note = note
        return copy
    }

    func date(_ date: Date) -> ExpenseBuilder {
        var copy = self
        copy.date = date
        return copy
    }

    /// Для редагування: зберегти id наявної витрати.
    func id(_ id: UUID) -> ExpenseBuilder {
        var copy = self
        copy.id = id
        return copy
    }

    func receiptID(_ receiptID: String?) -> ExpenseBuilder {
        var copy = self
        copy.receiptID = receiptID
        return copy
    }

    func build() throws -> Expense {
        let amount = try currency.parseMinor(amountText)
        guard amount > 0 else { throw WalletError.negativeAmount }
        guard let category else { throw WalletError.missingCategory }

        let trimmedNote = note?.trimmingCharacters(in: .whitespaces)
        return Expense(id: id,
                       amount: amount,
                       category: category,
                       date: date,
                       note: trimmedNote?.isEmpty == false ? trimmedNote : nil,
                       receiptID: receiptID)
    }
}
