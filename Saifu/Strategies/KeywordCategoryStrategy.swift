import Foundation

/// Шукає ключові слова зі словника в нотатці без урахування регістру.
struct KeywordCategoryStrategy: CategorySuggestionStrategy {
    private let dictionary: [String: ExpenseCategory]

    init(dictionary: [String: ExpenseCategory]) {
        self.dictionary = dictionary
    }

    func suggest(for note: String) -> ExpenseCategory? {
        let text = note.lowercased()
        // Найдовший збіг виграє, щоб результат не залежав від порядку у словнику
        return dictionary
            .filter { text.contains($0.key.lowercased()) }
            .max { $0.key.count < $1.key.count }?
            .value
    }
}
