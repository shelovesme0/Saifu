import Foundation

/// Демонстраційний сценарій: друкує кроки в консоль і повертає гаманці для показу в UI.
enum DemoScenario {
    @discardableResult
    static func run() -> [CashWallet] {
        // MARK: 1. Гаманець у єнах
        printStep(1, "Створення гаманця «Єни» (JPY)")
        let yen = CashWallet(name: "Єни", currency: .jpy)
        print("Гаманець: \(yen.name), валюта: \(yen.currency.code)")

        do {
            // MARK: 2. Поповнення
            printStep(2, "Поповнення з банкомату")
            try yen.addTopUp(CashTopUp(amount: 20_000, source: .atm))
            print("+ \(yen.currency.format(20_000))")

            // MARK: 3. Витрати
            printStep(3, "Витрати")
            let expenses = [
                Expense(amount: 580, category: .smallShop, note: "7-Eleven"),
                Expense(amount: 950, category: .food, note: "Обід"),
                Expense(amount: 3_000, category: .transport) // без нотатки (nil)
            ]
            for expense in expenses {
                try yen.addExpense(expense)
            }
            print(expenses.map { describe($0, in: yen.currency) }.joined(separator: "\n"))

            // MARK: 4. Очікуваний баланс
            printStep(4, "Очікуваний баланс")
            print("Баланс: \(yen.formattedBalance)")

            // MARK: 5. Звірка
            printStep(5, "Звірка: у гаманці реально \(yen.currency.format(15_100))")
            let result = try yen.reconcile(actualCash: 15_100)
            print("Очікувалось: \(yen.currency.format(result.expected)), фактично: \(yen.currency.format(result.actual))")
            // switch по знаку різниці
            switch result.difference {
            case 1...:
                print("Недостача \(yen.currency.format(result.difference)) записана як «\(ExpenseCategory.untracked.title)»")
            case ..<0:
                print("Надлишок \(yen.currency.format(-result.difference)) записаний як коригувальне поповнення")
            default:
                print("Баланс збігся")
            }

            // MARK: 6. Підсумки
            printStep(6, "Витрати за категоріями і баланс після звірки")
            print(yen.expenseSummaries().joined(separator: ", "))
            // Порядок категорій стабільний: беремо allCases
            for category in ExpenseCategory.allCases {
                if let total = yen.totalsByCategory()[category] {
                    print("\(category.emoji) \(category.title): \(yen.currency.format(total))")
                }
            }
            print("Баланс після звірки: \(yen.formattedBalance)")
        } catch {
            print("Помилка сценарію (єни): \(error)")
        }

        // MARK: 7. Гривні
        printStep(7, "Другий гаманець «Гривні» (UAH)")
        let hryvnia = CashWallet(name: "Гривні", currency: .uah)
        do {
            try hryvnia.addTopUp(CashTopUp(amount: 100_000))
            try hryvnia.addExpense(Expense(amount: 4_550, category: .groceries, note: "Магазин"))
            print("+ \(hryvnia.currency.format(100_000)), − \(hryvnia.currency.format(4_550))")
            print("Баланс: \(hryvnia.formattedBalance)")
        } catch {
            print("Помилка сценарію (гривні): \(error)")
        }

        // MARK: 8. Некоректна сума
        printStep(8, "Спроба додати витрату з від'ємною сумою")
        do {
            try hryvnia.addExpense(Expense(amount: -100, category: .food))
            print("Витрату додано (так бути не повинно)")
        } catch WalletError.negativeAmount {
            print("Помилка: сума має бути додатною, витрату не додано")
        } catch {
            print("Невідома помилка: \(error)")
        }
        print("Баланс без змін: \(hryvnia.formattedBalance)")

        return [yen, hryvnia]
    }

    private static func printStep(_ number: Int, _ title: String) {
        print("\n\(number). \(title)")
    }

    private static func describe(_ expense: Expense, in currency: Currency) -> String {
        // ?? підставляє текст, якщо нотатки немає
        "- \(expense.category.emoji) \(currency.format(expense.amount)) — \(expense.note ?? "без нотатки")"
    }
}
