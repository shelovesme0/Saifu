import Foundation
import Observation

/// Деталі витрати: редагування суми, категорії, нотатки та видалення.
@MainActor
@Observable
final class ExpenseDetailViewModel {
    private let wallet: CashWallet?
    private let expenseID: UUID
    private let repository: WalletRepository
    private let router: AppRouter

    var amountText = ""
    var category: ExpenseCategory?
    var note = ""
    private(set) var errorMessage: String?

    init(walletID: UUID, expenseID: UUID, repository: WalletRepository, router: AppRouter) {
        self.expenseID = expenseID
        self.repository = repository
        self.router = router
        wallet = repository.wallet(id: walletID)

        // Форма стартує з поточних значень витрати
        if let wallet, let expense = wallet.expense(with: expenseID) {
            amountText = wallet.currency.inputText(expense.amount)
            category = expense.category
            note = expense.note ?? ""
        }
    }

    /// Витрату читаємо з гаманця щоразу, тож бачимо актуальний стан, а не копію.
    private var expense: Expense? {
        wallet?.expense(with: expenseID)
    }

    var isMissing: Bool {
        expense == nil
    }

    var currencySymbol: String {
        wallet?.currency.symbol ?? ""
    }

    var dateText: String {
        expense?.date.formatted(date: .abbreviated, time: .shortened) ?? ""
    }

    /// Та сама валідація, що й при додаванні: ExpenseBuilder з id наявної витрати.
    func save() {
        guard let wallet, let expense else {
            errorMessage = WalletError.expenseNotFound.userMessage
            return
        }
        do {
            let updated = try ExpenseBuilder(currency: wallet.currency)
                .id(expense.id)
                .date(expense.date)
                .receiptID(expense.receiptID)
                .amount(amountText)
                .category(category)
                .note(note)
                .build()
            try wallet.updateExpense(updated)
            repository.save(wallet)
            errorMessage = nil
            router.pop()
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося зберегти витрату")
        }
    }

    func delete() {
        guard let wallet else { return }
        do {
            try wallet.removeExpense(id: expenseID)
            repository.save(wallet)
            errorMessage = nil
            router.pop()
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося видалити витрату")
        }
    }
}
