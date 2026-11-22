import Foundation
import Observation

/// Усі витрати гаманця з фільтром за категорією.
@MainActor
@Observable
final class ExpenseListViewModel {
    private let wallet: CashWallet?
    private let router: AppRouter

    /// nil — показувати всі категорії.
    var selectedCategory: ExpenseCategory?

    init(walletID: UUID, repository: WalletRepository, router: AppRouter) {
        self.router = router
        wallet = repository.wallet(id: walletID)
    }

    var title: String {
        wallet?.name ?? "Витрати"
    }

    /// Категорії, які є серед витрат, у сталому порядку allCases.
    var categoryOptions: [ExpenseCategory] {
        guard let wallet else { return [] }
        let used = Set(wallet.expenses.map(\.category))
        return ExpenseCategory.allCases.filter { used.contains($0) }
    }

    private var filteredExpenses: [Expense] {
        guard let wallet else { return [] }
        let expenses = selectedCategory.map { wallet.expenses(in: $0) } ?? wallet.expenses
        return expenses.sorted { $0.date > $1.date }
    }

    var rows: [EntryRow] {
        guard let wallet else { return [] }
        return filteredExpenses.map { EntryRow(expense: $0, currency: wallet.currency) }
    }

    func rowTapped(_ row: EntryRow) {
        guard let wallet, let expenseID = row.expenseID else { return }
        router.showExpenseDetail(walletID: wallet.id, expenseID: expenseID)
    }

    var totalText: String {
        guard let wallet else { return "" }
        return wallet.currency.format(filteredExpenses.reduce(0) { $0 + $1.amount })
    }
}
