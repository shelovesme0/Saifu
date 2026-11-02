import Foundation
import Observation

/// Рядок списку операцій, уже готовий для показу.
struct EntryRow: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let amountText: String
    let isNegative: Bool
}

@Observable
final class WalletViewModel {
    private let repository: WalletRepository

    private(set) var wallets: [CashWallet] = []
    var selectedIndex = 0 {
        didSet { reload() }
    }
    private(set) var balanceText = ""
    private(set) var rows: [EntryRow] = []
    private(set) var errorMessage: String?

    init(repository: WalletRepository) {
        self.repository = repository
        wallets = repository.wallets()
        reload()
    }

    var walletNames: [String] {
        wallets.map(\.name)
    }

    var selectedWallet: CashWallet? {
        wallets.indices.contains(selectedIndex) ? wallets[selectedIndex] : nil
    }

    /// View → ViewModel → ExpenseBuilder → CashWallet → Repository; після цього оновлюємо стан екрана.
    /// Повертає true, якщо витрату додано.
    @discardableResult
    func addExpense(amountText: String, category: ExpenseCategory?, note: String) -> Bool {
        guard let wallet = selectedWallet else { return false }
        do {
            let expense = try ExpenseBuilder(currency: wallet.currency)
                .amount(amountText)
                .category(category)
                .note(note)
                .build()
            try wallet.addExpense(expense)
            repository.save(wallet)
            errorMessage = nil
            reload()
            return true
        } catch WalletError.negativeAmount {
            errorMessage = "Сума має бути більшою за нуль"
        } catch WalletError.invalidAmount {
            errorMessage = "Некоректна сума"
        } catch WalletError.missingCategory {
            errorMessage = "Оберіть категорію"
        } catch {
            errorMessage = "Не вдалося додати витрату"
        }
        return false
    }

    /// Перерахунок стану екрана з поточного гаманця (CashWallet не спостережуваний).
    private func reload() {
        guard let wallet = selectedWallet else {
            balanceText = ""
            rows = []
            return
        }
        balanceText = wallet.formattedBalance
        let topUpRows = wallet.topUps.map { topUp in
            EntryRow(id: topUp.id,
                     title: topUp.source == .atm ? "🏧 Поповнення" : "➕ Коригування",
                     subtitle: nil,
                     amountText: wallet.currency.format(topUp.signedAmount),
                     isNegative: topUp.signedAmount < 0)
        }
        let expenseRows = wallet.expenses.map { expense in
            EntryRow(id: expense.id,
                     title: "\(expense.category.emoji) \(expense.category.title)",
                     subtitle: expense.note,
                     amountText: wallet.currency.format(expense.signedAmount),
                     isNegative: expense.signedAmount < 0)
        }
        rows = topUpRows + expenseRows
    }
}
