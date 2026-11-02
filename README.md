# Saifu

Saifu — iOS-застосунок для обліку готівкових витрат у будь-якій країні та валюті.

## Призначення

Готівку складно відстежувати: дрібні витрати не записуються, і підрахунок у застосунку «не сходиться» з тим, що реально лежить у гаманці. Saifu розв'язує це так: гаманець має **очікуваний баланс**, який рахується з поповнень і записаних витрат. Час від часу користувач **звіряє** його з реальною готівкою, а різниця записується як «невідстежені витрати».

Демо-приклад — Японія, де багато платять готівкою (єни).

## Користувач

Людина, яка часто платить готівкою. Зокрема:
- студент;
- мандрівник за кордоном, який хоче бачити витрати ще й у домашній валюті.

## Сценарії

1. **Поповнити гаманець** (зняття готівки в банкоматі).
2. **Швидко записати витрату** (сума, категорія, нотатка).
3. **Звірити гаманець із реальною готівкою**: ввести фактичну суму, а різницю зберегти як невідстежені витрати.
4. **Переглянути витрати за категорією.**
5. **Побачити суму витрат за період.**

## Сутності

Одна валюта на гаманець. Усі суми — `Int` у найменших одиницях валюти (єни, копійки, центи), ніколи не `Double`.

| Сутність | Призначення | Властивості |
|---|---|---|
| `Currency` | Валюта (enum) | `code` (наприклад, JPY, UAH, USD), `symbol`, `minorUnits` (кількість знаків після коми) |
| `Expense` | Витрата (`Identifiable`) | `let id: UUID`, `amount: Int` (у найменших одиницях), `category`, `date`, `note?`, `receiptID?` |
| `CashTopUp` | Поповнення гаманця (`Identifiable`) | `let id: UUID`, `amount`, `date`, `source: TopUpSource` |
| `TopUpSource` | Джерело поповнення (enum) | `atm` (банкомат), `correction` (коригувальне поповнення при надлишку) |
| `CashWallet` | Гаманець | `name`, `currency`, `expenses`, `topUps`, `lastReconciliation?` |
| `Reconciliation` | Результат звірки | `expected`, `actual`, `difference`, `date` |
| `WalletError` | Помилка операції з гаманцем (enum, `Error`) | `negativeAmount` (від'ємна або нульова сума витрати чи поповнення, від'ємна фактична готівка) |

`id` потрібен для пошуку `expense(with id:)`, для `List` у SwiftUI та для передачі `Expense.ID` між екранами.

Зв'язки:
- `CashWallet` має одну `Currency`.
- `CashWallet` має багато `Expense` і `CashTopUp`, а також останню звірку `lastReconciliation` (необов'язкова).
- Баланс = сума поповнень − сума витрат.
- Різниця: `difference = expected − actual`.
  - Недостача (`difference > 0`): записується витрата категорії `untracked`.
  - Надлишок (`difference < 0`): записується коригувальне поповнення із `source: .correction`.
- `addExpense`, `addTopUp` і `reconcile` кидають `WalletError.negativeAmount` при некоректній сумі.

Категорії загальні для всіх країн. Місцева специфіка (наприклад, назви магазинів) не входить у моделі, лише у словники підказки категорії.

## Технічні вимоги

| | |
|---|---|
| Xcode | 27.2 |
| Мінімальна iOS | 17.0 |
| Мова / UI | Swift, SwiftUI |
| Bundle ID | `com.vitaliilazariev.Saifu` |

### Підготовка і запуск

1. Клонувати репозиторій:
   ```sh
   git clone https://github.com/shelovesme0/Saifu.git
   cd Saifu
   ```
2. Відкрити `Saifu.xcodeproj` в Xcode 27.2. Проєкт використовує новий JSON-формат (`project.xcproj` замість `project.pbxproj`), тому старіші версії Xcode його не відкриють.
3. Вибрати схему `Saifu` і симулятор iPhone.
4. Запустити (⌘R) або зібрати з терміналу:
   ```sh
   xcodebuild -scheme Saifu -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```
   Назву симулятора замініть на ту, що встановлена (`xcrun simctl list devices available`).

## Де реалізовано конструкції Swift

| Конструкція | Файл | Тип/метод | Пояснення |
|---|---|---|---|
| `struct` | `Models/Expense.swift` | `Expense` | Значеннєвий тип: витрата копіюється при передачі |
| `struct` | `Models/CashTopUp.swift`, `Models/Reconciliation.swift` | `CashTopUp`, `Reconciliation` | Поповнення та результат звірки |
| `class` | `Models/CashWallet.swift` | `CashWallet` | Посилальний тип: один гаманець спільний для екранів, змінюється на місці |
| `protocol` | `Models/WalletEntry.swift` | `WalletEntry` | Спільний контракт `Expense` і `CashTopUp` (`amount`, `date`, `signedAmount`) |
| `enum` | `Models/Currency.swift` | `Currency` | Валюти з `rawValue` і `CaseIterable` |
| `enum` | `Models/ExpenseCategory.swift`, `Models/CashTopUp.swift`, `Models/WalletError.swift` | `ExpenseCategory`, `TopUpSource`, `WalletError` | Категорії, джерело поповнення, помилка гаманця (`Error`) |
| `let` | `Models/Expense.swift` | `Expense.id`, `Expense.date` | Незмінні після створення |
| `var` | `Models/Expense.swift` | `Expense.amount`, `Expense.category` | Змінювані значення |
| `var` (локальна) | `Models/Currency.swift` | `format(_:)` — `divisor`, `result` | Локальні змінні, що змінюються в циклі |
| Збережені властивості | `Models/CashWallet.swift` | `name`, `currency`, `lastReconciliation` | Дані гаманця; `private(set) var expenses`/`topUps` читаються ззовні, змінюються лише методами |
| Обчислювані властивості | `Models/Currency.swift`, `Models/CashWallet.swift`, `Models/Reconciliation.swift` | `Currency.code`/`symbol`/`minorUnits`, `CashWallet.expectedBalance`/`formattedBalance`, `Reconciliation.difference`, `Expense.signedAmount` | Значення рахуються з інших даних і не зберігаються |
| Методи | `Models/CashWallet.swift` | `addTopUp`, `addExpense`, `expense(with:)`, `expenses(in:)`, `totalsByCategory()`, `reconcile(actualCash:)` | Поведінка гаманця |
| `mutating` метод | `Models/Expense.swift` | `Expense.update(category:amount:)` | Змінює `struct` на місці |
| `init` | `Models/Expense.swift`, `Models/CashTopUp.swift`, `Models/Reconciliation.swift`, `Models/CashWallet.swift` | `Expense.init(...)`, `CashTopUp.init(...)`, `Reconciliation.init(...)`, `CashWallet.init(name:currency:)` | Ініціалізатори; у `struct` — зі значеннями за замовчуванням (`id`, `date`) |
| Колекції | `Models/CashWallet.swift` | `[Expense]`, `[CashTopUp]`, `[ExpenseCategory: Int]` | Масиви записів і словник підсумків |
| Optional | `Models/Expense.swift`, `Models/CashWallet.swift` | `Expense.note`, `Expense.receiptID`, `CashWallet.lastReconciliation` | Значення може бути відсутнім (`nil`) |
| `if let` | `Models/Expense.swift`, `ContentView.swift`, `Demo/DemoScenario.swift` | `Expense.update`, `ContentView.row`, `DemoScenario.run()` (крок 6) | Безпечне розгортання optional |
| `??` | `Models/CashWallet.swift`, `Demo/DemoScenario.swift` | `totalsByCategory()`, `describe(_:in:)` | Значення за замовчуванням для `nil` (0 або «без нотатки») |
| `guard` | `Models/CashWallet.swift` | `addTopUp`, `addExpense`, `reconcile(actualCash:)` | Рання відмова при некоректній сумі. `guard let` у коді не використовується |
| `if` | `Models/Currency.swift` | `format(_:)`, `groupThousands(_:)` | Умови: дробова частина лише для валют із копійками, пробіл між тисячами |
| `switch` | `Models/Currency.swift`, `Models/ExpenseCategory.swift`, `Models/CashWallet.swift` | `symbol`, `minorUnits`, `title`, `emoji`, `reconcile(actualCash:)` | Розгалуження по enum та по знаку різниці |
| `for-in` | `Models/CashWallet.swift`, `Models/Currency.swift`, `Demo/DemoScenario.swift` | `totalsByCategory()`, `format(_:)`, `groupThousands(_:)`, `run()` | Перебір записів, цифр, категорій |
| `filter` | `Models/CashWallet.swift` | `expenses(in:)` | Витрати однієї категорії |
| `map` | `Models/CashWallet.swift`, `Demo/DemoScenario.swift` | `expenseSummaries()`, `run()` (крок 3) | Перетворення витрат на рядки |
| `reduce` | `Models/CashWallet.swift` | `expectedBalance` | Баланс як сума `signedAmount` по всіх записах |
| `throws` | `Models/CashWallet.swift` | `addTopUp`, `addExpense`, `reconcile(actualCash:)` | Методи кидають `WalletError.negativeAmount` |
| `do` / `try` / `catch` | `Demo/DemoScenario.swift` | `run()` (кроки 2–8) | Виклики, що кидають помилки; у кроці 8 перехоплюється `WalletError.negativeAmount` |

## Як перевірити сценарій

1. Відкрити `Saifu.xcodeproj` в Xcode 27.2 або новішому.
2. Обрати симулятор iPhone.
3. Запустити застосунок (⌘R).
4. Відкрити консоль (⇧⌘C).

На екрані з'являється список із двома гаманцями («Єни» та «Гривні») та їхніми операціями. У консолі при старті друкується сценарій із 8 кроків:

1. **Створення гаманця «Єни» (JPY).**
2. **Поповнення:** `+ 20 000 ¥`.
3. **Витрати:** 7-Eleven 580 ¥, обід 950 ¥ та ICOCA 3 000 ¥ (остання без нотатки, виводиться «без нотатки»).
4. **Очікуваний баланс:** `15 470 ¥`.
5. **Звірка:** у гаманці реально 15 100 ¥, недостача `370 ¥` записується як «Невідстежене».
6. **Витрати за категоріями** (🏪 580 ¥, 🍜 950 ¥, 🚆 3 000 ¥, ❓ 370 ¥) і баланс після звірки: `15 100 ¥`.
7. **Гаманець «Гривні» (UAH):** `+ 1 000,00 ₴, − 45,50 ₴`, баланс `954,50 ₴`.
8. **Від'ємна сума:** перехоплена помилка `WalletError.negativeAmount`, у консолі «Помилка: сума має бути додатною, витрату не додано», баланс лишається `954,50 ₴`.

Системні повідомлення симулятора в кінці консолі не є помилками застосунку.

## Внесок учасників

Індивідуальна робота.
