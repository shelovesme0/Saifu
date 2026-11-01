import Foundation

struct Expense: WalletEntry {
    let id: UUID
    var amount: Int
    var category: ExpenseCategory
    let date: Date
    var note: String?
    /// Лише для відсканованих чеків (майбутні лаби).
    var receiptID: String?

    var signedAmount: Int { -amount }

    init(
        id: UUID = UUID(),
        amount: Int,
        category: ExpenseCategory,
        date: Date = Date(),
        note: String? = nil,
        receiptID: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
        self.receiptID = receiptID
    }

    /// Змінює категорію та/або суму. Не передані параметри лишаються без змін.
    mutating func update(category newCategory: ExpenseCategory? = nil, amount newAmount: Int? = nil) {
        // if let: розпаковуємо необов'язкові значення
        if let newCategory {
            category = newCategory
        }
        if let newAmount {
            amount = newAmount
        }
    }
}
