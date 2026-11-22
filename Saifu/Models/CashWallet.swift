import Foundation
import Observation

/// Гаманець в одній валюті. Баланс рахується з поповнень і витрат.
/// @Observable: усі екрани, що читають гаманець, оновлюються після змін.
@Observable
final class CashWallet: Identifiable {
    let id: UUID
    let name: String
    let currency: Currency
    private(set) var expenses: [Expense] = []
    private(set) var topUps: [CashTopUp] = []
    /// nil, поки гаманець жодного разу не звіряли.
    var lastReconciliation: Reconciliation?

    init(id: UUID = UUID(), name: String, currency: Currency) {
        self.id = id
        self.name = name
        self.currency = currency
    }

    // MARK: - Додавання записів

    func addTopUp(_ topUp: CashTopUp) throws {
        // guard: рання відмова при некоректній сумі
        guard topUp.amount > 0 else { throw WalletError.negativeAmount }
        topUps.append(topUp)
    }

    func addExpense(_ expense: Expense) throws {
        guard expense.amount > 0 else { throw WalletError.negativeAmount }
        expenses.append(expense)
    }

    /// Замінює витрату з тим самим id. Ті самі перевірки, що й при додаванні.
    func updateExpense(_ expense: Expense) throws {
        guard expense.amount > 0 else { throw WalletError.negativeAmount }
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            throw WalletError.expenseNotFound
        }
        expenses[index] = expense
    }

    func removeExpense(id: Expense.ID) throws {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else {
            throw WalletError.expenseNotFound
        }
        expenses.remove(at: index)
    }

    /// Пошук витрати за id; повертає nil, якщо не знайдено.
    func expense(with id: Expense.ID) -> Expense? {
        expenses.first { $0.id == id }
    }

    // MARK: - Баланс

    private var allEntries: [any WalletEntry] {
        (topUps as [any WalletEntry]) + (expenses as [any WalletEntry])
    }

    /// reduce по протоколу WalletEntry: однаково для витрат і поповнень.
    var expectedBalance: Int {
        allEntries.reduce(0) { $0 + $1.signedAmount }
    }

    var formattedBalance: String {
        currency.format(expectedBalance)
    }

    // MARK: - Вибірки

    /// filter: витрати однієї категорії.
    func expenses(in category: ExpenseCategory) -> [Expense] {
        expenses.filter { $0.category == category }
    }

    /// for-in: сума витрат за кожною категорією. Категорії без витрат у результат не потрапляють.
    func totalsByCategory() -> [ExpenseCategory: Int] {
        var totals: [ExpenseCategory: Int] = [:]
        for expense in expenses {
            // ?? дає 0, якщо категорії ще немає у словнику
            totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount
        }
        return totals
    }

    /// map: короткий опис кожної витрати для списку, наприклад "🍜 580 ¥".
    func expenseSummaries() -> [String] {
        expenses.map { "\($0.category.emoji) \(currency.format($0.amount))" }
    }

    // MARK: - Звірка

    /// Звіряє баланс із реальною готівкою. Недостачу записує як витрату `untracked`,
    /// надлишок — як коригувальне поповнення. Після цього баланс дорівнює `actualCash`.
    @discardableResult
    func reconcile(actualCash: Int) throws -> Reconciliation {
        guard actualCash >= 0 else { throw WalletError.negativeAmount }

        let reconciliation = Reconciliation(expected: expectedBalance, actual: actualCash)
        let difference = reconciliation.difference

        // switch по знаку різниці
        switch difference {
        case 1...:
            try addExpense(Expense(amount: difference, category: .untracked, note: "Звірка: недостача"))
        case ..<0:
            try addTopUp(CashTopUp(amount: -difference, source: .correction))
        default:
            break // баланс збігся, нічого не додаємо
        }

        lastReconciliation = reconciliation
        return reconciliation
    }
}
