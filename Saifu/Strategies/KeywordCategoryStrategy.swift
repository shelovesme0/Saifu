import Foundation

/// Шукає ключові слова зі словника в нотатці без урахування регістру, лише цілими словами/фразами.
struct KeywordCategoryStrategy: CategorySuggestionStrategy {
    private let dictionary: [String: ExpenseCategory]

    init(dictionary: [String: ExpenseCategory]) {
        self.dictionary = dictionary
    }

    func suggest(for note: String) -> ExpenseCategory? {
        let text = note.lowercased()
        // Найдовший збіг виграє, щоб результат не залежав від порядку у словнику
        return dictionary
            .filter { containsWhole(text, keyword: $0.key.lowercased()) }
            .max { $0.key.count < $1.key.count }?
            .value
    }

    /// Збіг рахується, якщо з обох боків ключа немає літери чи цифри: "bus" не в "business", "7-Eleven" як фраза.
    private func containsWhole(_ text: String, keyword: String) -> Bool {
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: keyword, range: searchRange) {
            let startsWord = range.lowerBound == text.startIndex || !isWordCharacter(text[text.index(before: range.lowerBound)])
            let endsWord = range.upperBound == text.endIndex || !isWordCharacter(text[range.upperBound])
            if startsWord && endsWord {
                return true
            }
            searchRange = text.index(after: range.lowerBound)..<text.endIndex
        }
        return false
    }

    private func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }
}
