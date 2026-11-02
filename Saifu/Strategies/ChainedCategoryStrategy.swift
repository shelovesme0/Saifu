import Foundation

/// Питає стратегії по черзі й повертає першу відповідь.
struct ChainedCategoryStrategy: CategorySuggestionStrategy {
    private let strategies: [any CategorySuggestionStrategy]

    init(_ strategies: [any CategorySuggestionStrategy]) {
        self.strategies = strategies
    }

    func suggest(for note: String) -> ExpenseCategory? {
        for strategy in strategies {
            if let category = strategy.suggest(for: note) {
                return category
            }
        }
        return nil
    }

    func learn(note: String, category: ExpenseCategory) {
        strategies.forEach { $0.learn(note: note, category: category) }
    }
}
