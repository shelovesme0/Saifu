import Foundation

/// Повертає категорію, яку користувач уже обирав для такої самої нотатки.
final class LastUsedCategoryStrategy: CategorySuggestionStrategy {
    private var categories: [String: ExpenseCategory] = [:]

    func suggest(for note: String) -> ExpenseCategory? {
        categories[normalize(note)]
    }

    func learn(note: String, category: ExpenseCategory) {
        let key = normalize(note)
        guard !key.isEmpty else { return }
        categories[key] = category
    }

    private func normalize(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
