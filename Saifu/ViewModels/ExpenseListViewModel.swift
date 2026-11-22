import Foundation
import Observation

/// Витрати одного дня для списку.
struct DaySection: Identifiable, Equatable {
    let id: Date
    let title: String
    let rows: [EntryRow]
}

/// Усі витрати гаманця з фільтром за категорією, згруповані за днями.
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
        guard let wallet else { return "Витрати" }
        return "\(wallet.name) · \(wallet.currency.code)"
    }

    /// Категорії, які є серед витрат, у сталому порядку allCases.
    /// Обрана категорія лишається у списку, навіть якщо її витрати змінили чи видалили.
    var categoryOptions: [ExpenseCategory] {
        guard let wallet else { return [] }
        var used = Set(wallet.expenses.map(\.category))
        if let selectedCategory {
            used.insert(selectedCategory)
        }
        return ExpenseCategory.allCases.filter { used.contains($0) }
    }

    private var filteredExpenses: [Expense] {
        guard let wallet else { return [] }
        let expenses = selectedCategory.map { wallet.expenses(in: $0) } ?? wallet.expenses
        return expenses.sorted { $0.date > $1.date }
    }

    /// Групи за днями, нові зверху.
    var sections: [DaySection] {
        guard let wallet else { return [] }
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            DaySection(id: day,
                       title: Self.dayTitle(day, calendar: calendar),
                       rows: (grouped[day] ?? []).map { EntryRow(expense: $0, currency: wallet.currency) })
        }
    }

    var isEmpty: Bool {
        filteredExpenses.isEmpty
    }

    var totalText: String {
        guard let wallet else { return "" }
        return wallet.currency.format(filteredExpenses.reduce(0) { $0 + $1.amount })
    }

    /// "1 витрата", "3 витрати", "5 витрат".
    var countText: String {
        let count = filteredExpenses.count
        let word: String
        switch (count % 10, count % 100) {
        case (1, let tens) where tens != 11: word = "витрата"
        case (2...4, let tens) where !(12...14).contains(tens): word = "витрати"
        default: word = "витрат"
        }
        return "\(count) \(word)"
    }

    func rowTapped(_ row: EntryRow) {
        guard let wallet, let expenseID = row.expenseID else { return }
        router.showExpenseDetail(walletID: wallet.id, expenseID: expenseID)
    }

    func backTapped() {
        router.pop()
    }

    private static func dayTitle(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Сьогодні" }
        if calendar.isDateInYesterday(day) { return "Вчора" }
        return day.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "uk_UA")))
    }
}
