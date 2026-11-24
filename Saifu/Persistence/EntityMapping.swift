import Foundation

// Перетворення між сутностями сховища й доменними моделями. Enum-и зберігаються через rawValue.

extension WalletEntity {
    /// nil, якщо валюту не вдалося розпізнати (наприклад, її прибрали з `Currency`).
    func toDomain() -> CashWallet? {
        guard let currency = Currency(rawValue: currencyRaw) else {
            assertionFailure("Невідома валюта у сховищі: \(currencyRaw)")
            return nil
        }
        return CashWallet(id: id,
                          name: name,
                          currency: currency,
                          expenses: expenses.map { $0.toDomain() },
                          topUps: topUps.map { $0.toDomain() },
                          lastReconciliation: lastReconciliation?.toDomain())
    }

    /// Поля самого гаманця (без записів і звірки).
    func update(from wallet: CashWallet) {
        name = wallet.name
        currencyRaw = wallet.currency.rawValue
    }
}

extension ExpenseEntity {
    convenience init(_ expense: Expense) {
        self.init(id: expense.id,
                  amount: expense.amount,
                  categoryRaw: expense.category.rawValue,
                  date: expense.date,
                  note: expense.note,
                  receiptID: expense.receiptID)
    }

    func toDomain() -> Expense {
        Expense(id: id,
                amount: amount,
                // Невідома категорія не губить витрату, а стає «невідстеженою»
                category: ExpenseCategory(rawValue: categoryRaw) ?? .untracked,
                date: date,
                note: note,
                receiptID: receiptID)
    }

    /// `date` у витрати незмінна, тому оновлюються лише змінні поля.
    func update(from expense: Expense) {
        amount = expense.amount
        categoryRaw = expense.category.rawValue
        note = expense.note
        receiptID = expense.receiptID
    }
}

extension TopUpEntity {
    convenience init(_ topUp: CashTopUp) {
        self.init(id: topUp.id, amount: topUp.amount, date: topUp.date, sourceRaw: topUp.source.rawValue)
    }

    func toDomain() -> CashTopUp {
        CashTopUp(id: id, amount: amount, date: date, source: TopUpSource(rawValue: sourceRaw) ?? .atm)
    }

    func update(from topUp: CashTopUp) {
        amount = topUp.amount
    }
}

extension ReconciliationEntity {
    convenience init(_ reconciliation: Reconciliation) {
        self.init(expected: reconciliation.expected, actual: reconciliation.actual, date: reconciliation.date)
    }

    func toDomain() -> Reconciliation {
        Reconciliation(expected: expected, actual: actual, date: date)
    }
}
