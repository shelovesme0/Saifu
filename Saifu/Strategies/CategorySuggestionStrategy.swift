import Foundation

/// Підказує категорію витрати за нотаткою.
protocol CategorySuggestionStrategy {
    func suggest(for note: String) -> ExpenseCategory?
    /// Викликається після додавання витрати; стратегії без пам'яті нічого не роблять.
    func learn(note: String, category: ExpenseCategory)
}

extension CategorySuggestionStrategy {
    func learn(note: String, category: ExpenseCategory) {}
}
