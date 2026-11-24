import Foundation
import Observation

/// Форма швидкого додавання витрати на головному екрані. Працює з тим самим екземпляром гаманця, що й інші екрани.
@MainActor
@Observable
final class AddExpenseViewModel {
    private let wallet: CashWallet?
    private let repository: WalletRepository
    private let categoryStrategy: any CategorySuggestionStrategy

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
         categoryStrategy: any CategorySuggestionStrategy) {
        self.repository = repository
        self.categoryStrategy = categoryStrategy
        wallet = repository.wallet(id: walletID)
    }

    var currency: Currency {
        wallet?.currency ?? .uah
    }

    /// Кнопку «+» вмикаємо, щойно введено суму.
    var canSave: Bool {
        !amountText.isEmpty
    }

    /// View → ViewModel → ExpenseBuilder → CashWallet → Repository → очищення форми.
    /// Повертає true, якщо витрату додано.
    @discardableResult
    func save() -> Bool {
        guard let wallet else {
            errorMessage = "Гаманець не знайдено"
            return false
        }
        do {
            let expense = try ExpenseBuilder(currency: wallet.currency)
                .amount(amountText)
                .category(category)
                .note(note)
                .build()
            try wallet.addExpense(expense)
            try repository.save(wallet)
            if let note = expense.note {
                categoryStrategy.learn(note: note, category: expense.category)
            }
            reset()
            return true
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося додати витрату")
            return false
        }
    }

    private func reset() {
        amountText = ""
        note = ""
        category = nil
        suggestedCategory = nil
        errorMessage = nil
    }

    private func applySuggestion() {
        suggestedCategory = categoryStrategy.suggest(for: note)
        if let suggestedCategory {
            category = suggestedCategory
        }
    }
}
