import Foundation
import Observation

/// Форма нової витрати (sheet). Працює з тим самим екземпляром гаманця, що й інші екрани.
@MainActor
@Observable
final class AddExpenseViewModel {
    private let wallet: CashWallet?
    private let repository: WalletRepository
    private let categoryStrategy: any CategorySuggestionStrategy
    private let router: AppRouter

    var amountText = ""
    var category: ExpenseCategory?
    var note = "" {
        didSet { applySuggestion() }
    }
    /// Остання підказка стратегії, щоб показати її під формою.
    private(set) var suggestedCategory: ExpenseCategory?
    private(set) var errorMessage: String?

    init(walletID: UUID,
         repository: WalletRepository,
         categoryStrategy: any CategorySuggestionStrategy,
         router: AppRouter) {
        self.repository = repository
        self.categoryStrategy = categoryStrategy
        self.router = router
        wallet = repository.wallet(id: walletID)
    }

    var walletTitle: String {
        guard let wallet else { return "" }
        return "\(wallet.name) · \(wallet.currency.symbol)"
    }

    /// View → ViewModel → ExpenseBuilder → CashWallet → Repository → закриття sheet.
    func save() {
        guard let wallet else {
            errorMessage = "Гаманець не знайдено"
            return
        }
        do {
            let expense = try ExpenseBuilder(currency: wallet.currency)
                .amount(amountText)
                .category(category)
                .note(note)
                .build()
            try wallet.addExpense(expense)
            repository.save(wallet)
            if let note = expense.note {
                categoryStrategy.learn(note: note, category: expense.category)
            }
            errorMessage = nil
            router.dismissSheet()
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося додати витрату")
        }
    }

    func cancel() {
        router.dismissSheet()
    }

    private func applySuggestion() {
        suggestedCategory = categoryStrategy.suggest(for: note)
        if let suggestedCategory {
            category = suggestedCategory
        }
    }
}
