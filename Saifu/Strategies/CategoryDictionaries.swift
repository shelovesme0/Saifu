import Foundation

/// Словники ключових слів. Новий словник — ще один `static let`, класи стратегій не змінюються.
enum CategoryDictionaries {
    static let english: [String: ExpenseCategory] = [
        "7-Eleven": .smallShop,
        "Lawson": .smallShop,
        "FamilyMart": .smallShop,
        "ICOCA": .transport,
        "metro": .transport,
        "bus": .transport,
        "cafe": .food,
        "lunch": .food,
        "supermarket": .groceries
    ]

    static let ukrainian: [String: ExpenseCategory] = [
        "АТБ": .groceries,
        "Сільпо": .groceries,
        "Новус": .groceries,
        "кава": .food,
        "обід": .food,
        "метро": .transport,
        "таксі": .transport
    ]

    /// Усі словники разом; новий словник додається сюди одним рядком.
    static let all: [String: ExpenseCategory] = [english, ukrainian]
        .reduce(into: [:]) { result, dictionary in
            result.merge(dictionary) { first, _ in first }
        }
}
