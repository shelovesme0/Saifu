import Foundation

/// Збирає `Expense` з рядка суми, категорії, нотатки та дати. Кожен метод повертає копію.
struct ExpenseBuilder {
    private let currency: Currency
    private var amountText = ""
    private var category: ExpenseCategory?
    private var note: String?
    private var date = Date()

    init(currency: Currency) {
        self.currency = currency
    }

    func amount(_ text: String) -> ExpenseBuilder {
        var copy = self
        copy.amountText = text
        return copy
    }

    func category(_ category: ExpenseCategory?) -> ExpenseBuilder {
        var copy = self
        copy.category = category
        return copy
    }

    func note(_ note: String?) -> ExpenseBuilder {
        var copy = self
        copy.note = note
        return copy
    }

    func date(_ date: Date) -> ExpenseBuilder {
        var copy = self
        copy.date = date
        return copy
    }

    func build() throws -> Expense {
        let amount = try parseAmount()
        guard amount > 0 else { throw WalletError.negativeAmount }
        guard let category else { throw WalletError.missingCategory }

        let trimmedNote = note?.trimmingCharacters(in: .whitespaces)
        return Expense(amount: amount,
                       category: category,
                       date: date,
                       note: trimmedNote?.isEmpty == false ? trimmedNote : nil)
    }

    /// "45,50" або "45.50" → 4550 (без Double).
    private func parseAmount() throws -> Int {
        let normalized = amountText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, let whole = Int(parts[0]) else { throw WalletError.invalidAmount }

        var fractionDigits = parts.count == 2 ? String(parts[1]) : ""
        guard fractionDigits.count <= currency.minorUnits,
              fractionDigits.allSatisfy(\.isNumber) else { throw WalletError.invalidAmount }
        // Доповнюємо нулями справа: "5" при 2 знаках → "50"
        fractionDigits += String(repeating: "0", count: currency.minorUnits - fractionDigits.count)

        var divisor = 1
        for _ in 0..<currency.minorUnits { divisor *= 10 }
        return whole * divisor + (Int(fractionDigits) ?? 0)
    }
}
