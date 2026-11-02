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

    /// View → ViewModel → CashWallet → Repository; після цього оновлюємо стан екрана.
    /// Повертає true, якщо витрату додано.
    @discardableResult
    func addExpense(amountText: String, category: ExpenseCategory) -> Bool {
        guard let wallet = selectedWallet else { return false }
        guard let amount = parseAmount(amountText, currency: wallet.currency) else {
            errorMessage = "Некоректна сума"
            return false
        }
        do {
            try wallet.addExpense(Expense(amount: amount, category: category))
            repository.save(wallet)
            errorMessage = nil
            reload()
            return true
        } catch WalletError.negativeAmount {
            errorMessage = "Сума має бути більшою за нуль"
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

    /// "45,50" або "45.50" → 4550 (без Double). nil, якщо текст не число або знаків забагато.
    private func parseAmount(_ text: String, currency: Currency) -> Int? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, let whole = Int(parts[0]) else { return nil }

        var fractionDigits = parts.count == 2 ? String(parts[1]) : ""
        guard fractionDigits.count <= currency.minorUnits,
              fractionDigits.allSatisfy(\.isNumber) else { return nil }
        // Доповнюємо нулями справа: "5" при 2 знаках → "50"
        fractionDigits += String(repeating: "0", count: currency.minorUnits - fractionDigits.count)

        var divisor = 1
        for _ in 0..<currency.minorUnits { divisor *= 10 }
        return whole * divisor + (Int(fractionDigits) ?? 0)
    }
}
