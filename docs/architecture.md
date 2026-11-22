# Архітектура Saifu

Практична робота 2: MVVM, патерни Builder / Strategy / Adapter, принципи SOLID.
Практична робота 3: п'ять екранів, навігація через `AppRouter`, спільний стан між екранами.

## Чому MVVM

- **MVC.** У SwiftUI роль контролера відсутня. Логіка опинилася б у `View` або в моделі. Саме так було до рефакторингу: `ContentView` вибирав заголовки рядків і кольори, а `CashWallet` повертав відформатовані рядки.
- **VIPER.** Дає п'ять шарів на кожен екран (View, Interactor, Presenter, Entity, Router). Навіть для п'яти невеликих екранів це багато шаблонного коду без користі. Від VIPER взято лише роутер (`AppRouter`).
- **MVVM.** Підходить до `@Observable` і декларативного UI. View лише показує стан і викликає методи ViewModel. ViewModel отримує залежності через `init`, тому їх легко підміняти. У лабі 3 каркас розширився саме так: кожен новий екран отримав власну ViewModel.

## Схема компонентів

Стрілка означає «залежить від».

```mermaid
graph TD
    App["SaifuApp<br/>(композиційний корінь)"]
    Factory["ScreenFactory"]
    Router["AppRouter<br/>(path, sheet)"]
    Root["RootView<br/>(NavigationStack + sheet)"]
    Views["WalletView · ExpenseListView · ExpenseDetailView<br/>AddExpenseView · ReconcileView"]
    VMs["WalletViewModel · ExpenseListViewModel · ExpenseDetailViewModel<br/>AddExpenseViewModel · ReconcileViewModel"]
    Repo["WalletRepository<br/>(protocol)"]
    Strat["CategorySuggestionStrategy<br/>(protocol)"]
    Rate["ExchangeRateProvider<br/>(protocol)"]
    Builder["ExpenseBuilder"]
    Wallet["CashWallet (@Observable) + моделі"]
    InMem["InMemoryWalletRepository"]
    Demo["DemoWalletRepository"]
    Chain["ChainedCategoryStrategy"]
    Kw["KeywordCategoryStrategy"]
    Last["LastUsedCategoryStrategy"]
    Adapter["NBURateAdapter"]
    Source["NBURecordSource<br/>(protocol)"]
    DemoSrc["DemoNBURecordSource"]

    App -->|створює| Factory
    App -->|створює| Router
    App --> Root
    Root --> Router
    Root --> Factory
    Factory -->|створює| Views
    Factory -->|створює| VMs
    Views --> VMs
    VMs --> Router
    VMs --> Repo
    VMs --> Strat
    VMs --> Rate
    VMs --> Builder
    VMs --> Wallet
    Builder --> Wallet
    Repo --> Wallet
    InMem -.реалізує.-> Repo
    Demo -.реалізує.-> Repo
    Demo --> InMem
    Chain -.реалізує.-> Strat
    Kw -.реалізує.-> Strat
    Last -.реалізує.-> Strat
    Chain --> Kw
    Chain --> Last
    Adapter -.реалізує.-> Rate
    Adapter --> Source
    DemoSrc -.реалізує.-> Source
```

View не знають про репозиторій, стратегію, курси й роутер. Усе це доступно лише через їхні ViewModel. Конкретні типи (`DemoWalletRepository`, `ChainedCategoryStrategy`, `NBURateAdapter`, `DemoNBURecordSource`, `AppRouter`) створюються тільки в `SaifuApp`. `ScreenFactory` отримує їх через `init` і збирає з них екрани.

## Навігація: `AppRouter`

- **Стан.** `Saifu/Navigation/AppRouter.swift`, `@Observable`. `path: [Route]` для `NavigationStack`, `sheet: Sheet?` для модальних екранів.
- **Маршрути.**
  - `Route.expenseList(walletID:)`, `Route.expenseDetail(walletID:expenseID:)` (push).
  - `Sheet.addExpense(walletID:)`, `Sheet.reconcile(walletID:)` (sheet).
  - Маршрути несуть лише ідентифікатори, а не копії моделей.
- **Методи.** `showExpenseList`, `showExpenseDetail`, `presentAddExpense`, `presentReconcile`, `dismissSheet`, `pop`. Переходи відбуваються тільки через них.
- **Хто викликає.** View викликає метод своєї ViewModel (наприклад, `addExpenseTapped()`), а ViewModel звертається до роутера. Так ViewModel вирішує, куди йти після операції: `dismissSheet()` після збереження, `pop()` після редагування чи видалення.
- **Прив'язка до SwiftUI.** Лише `RootView` бере binding `$router.path` і `$router.sheet` та питає `ScreenFactory`, який екран показати для `Route` чи `Sheet`.

| Екран | Тип | Звідки відкривається |
|---|---|---|
| `WalletView` | корінь стеку | старт застосунку |
| `AddExpenseView` | sheet | «+ Витрата» на головному |
| `ReconcileView` | sheet | «Звірити» на головному |
| `ExpenseListView` | push | «Усі витрати» на головному |
| `ExpenseDetailView` | push | рядок витрати в списку або на головному |

## Спільний стан між екранами

- `CashWallet` позначено `@Observable`. Репозиторій повертає ті самі екземпляри, тому всі ViewModel працюють з одним об'єктом гаманця.
- Баланс, рядки та список є обчислюваними властивостями ViewModel. SwiftUI сам відстежує, що читається з гаманця, і перемальовує всі екрани, що від нього залежать.
- Після додавання в sheet, звірки, редагування чи видалення головний екран і список оновлюються без `reload()` і без копіювання даних.
- `ExpenseDetailViewModel` читає витрату з гаманця щоразу за `expenseID`. Якщо витрати вже немає, екран показує «Витрату не знайдено».
- Курс НБУ запитується лише при зміні гаманця, а `≈ ₴` рахується з живого балансу.
- Для редагування до `CashWallet` додано `updateExpense(_:)` і `removeExpense(id:)`. Вони мають ті самі перевірки, що й `addExpense`: `negativeAmount`, а для відсутньої витрати новий `WalletError.expenseNotFound`. Гаманець отримав `id`, і `InMemoryWalletRepository.save` шукає за ним, а не за `name`.

## Патерни

### Builder: `ExpenseBuilder`

- **Задача.** Перетворити введення форми (рядок «45,50», необов'язкові категорія й нотатка) на коректну `Expense`. Суму треба перевести в найменші одиниці за `currency.minorUnits` без `Double` і перевірити: сума більша за нуль, категорію задано.
- **Учасники.** `ExpenseBuilder` (будівельник), `Expense` (продукт), `WalletError` (`invalidAmount`, `negativeAmount`, `missingCategory`). Клієнти: `AddExpenseViewModel` (нова витрата) та `ExpenseDetailViewModel` (редагування, з `id(_:)`, `date(_:)`, `receiptID(_:)` наявної витрати, щоб валідація була одна).
- **Особливість.** Методи `amount`, `category`, `note`, `date`, `id`, `receiptID` повертають копію структури, тож будівельник є значенням без прихованого стану. Розбір рядка суми винесено в `Currency.parseMinor`, бо його використовує й `ReconcileViewModel`.
- **Файли.** `Saifu/Builders/ExpenseBuilder.swift`, `Saifu/Models/WalletError.swift`, `Saifu/Models/Currency.swift`, використання в `Saifu/ViewModels/AddExpenseViewModel.swift` і `Saifu/ViewModels/ExpenseDetailViewModel.swift`.

### Strategy: `CategorySuggestionStrategy`

- **Задача.** Підказувати категорію за нотаткою. Спосіб підказки має змінюватися без правок ViewModel.
- **Учасники.**
  - Протокол `CategorySuggestionStrategy` (`suggest(for:)`, `learn(note:category:)` зі стандартною порожньою реалізацією).
  - `KeywordCategoryStrategy(dictionary:)` шукає цілі слова та фрази без урахування регістру, найдовший збіг виграє.
  - `LastUsedCategoryStrategy` пригадує категорію, яку користувач уже обирав для такої нотатки.
  - `CategoryDictionaries` містить дані (`english`, `ukrainian`, `all`).
  - Контекст — `AddExpenseViewModel`.
- **Файли.** `Saifu/Strategies/*.swift`.

#### Роль `ChainedCategoryStrategy`

`AddExpenseViewModel` приймає одну стратегію, а застосунку потрібні дві: спочатку те, що користувач уже обирав, і лише потім словник. `ChainedCategoryStrategy` реалізує той самий протокол і перебирає вкладені стратегії по черзі. Повертається перша відповідь, а `learn` передається всім. Порядок у масиві задає пріоритет. ViewModel не знає, що за стратегією ховається кілька. Так само працює патерн Composite, і це не штучна ієрархія: тип замінює складну умову у ViewModel.

### Adapter: `NBURateAdapter`

- **Задача.** Дані НБУ мають власний формат (`r030`, `txt`, `rate`, `cc`, `exchangedate` у вигляді `dd.MM.yyyy`). Застосунок працює зі своїм типом `ExchangeRate`.
- **Учасники.**
  - `ExchangeRateProvider` — цільовий інтерфейс, його використовує `WalletViewModel`.
  - `NBURecord` — формат, що адаптується.
  - `NBURateAdapter` — адаптер. Невідомий код валюти або дата, що не розбирається, дають `nil`.
  - `NBURecordSource` — джерело записів, `DemoNBURecordSource` — його демо-реалізація.
- **Конвертація.** `ExchangeRate.toUAHMinor` рахує через `Decimal`, без `Double`.
- **Файли.** `Saifu/ExchangeRates/*.swift`.

> **Примітка.** Курси в `DemoNBURecordSource` ілюстративні. Реальні дані з API НБУ з'являться в лабі 4.

## SOLID у Saifu

**S: єдина відповідальність.**
- `ExpenseBuilder` лише збирає й перевіряє витрату.
- `NBURateAdapter` лише перетворює формат.
- `EntryRow` лише готує рядок для показу.
- `AppRouter` лише зберігає стан навігації, а `ScreenFactory` лише збирає екрани.
- У лабі 3 `WalletViewModel` розбито: форма перейшла в `AddExpenseViewModel`, звірка в `ReconcileViewModel`, список і деталі мають власні ViewModel. Тексти помилок зібрано в одному місці, `WalletError+Message.swift`.

**O: відкритість до розширення.**
- Новий словник додається у `CategoryDictionaries` одним `static let`, класи стратегій не змінюються.
- Нова стратегія додається в `ChainedCategoryStrategy([...])` у `SaifuApp`.
- Новий екран означає новий випадок `Route`/`Sheet`, метод роутера та гілку в `ScreenFactory`. Наявні екрани не змінюються.

**L: підстановка Лісков.**
- Будь-яка реалізація `WalletRepository`, `CategorySuggestionStrategy` чи `ExchangeRateProvider` замінює іншу без змін у ViewModel.
- Наприклад, `InMemoryWalletRepository` і `DemoWalletRepository` взаємозамінні, а `ChainedCategoryStrategy` сама є стратегією.
- Спадкування тут не використовується, тому принцип виявляється лише через протоколи.

**I: розділення інтерфейсів.**
- `NBURecordSource` має один метод, `ExchangeRateProvider` також один.
- `learn(note:category:)` має стандартну порожню реалізацію, тому `KeywordCategoryStrategy` не змушений реалізовувати непотрібне.
- Чесне застереження: `WalletRepository` має два методи. Пошук `wallet(id:)` додано стандартною реалізацією в extension, тож реалізації протоколу його не пишуть. Ділити протокол поки не потрібно.

**D: інверсія залежностей.**
- ViewModel залежать від протоколів `WalletRepository`, `CategorySuggestionStrategy`, `ExchangeRateProvider` і отримують їх через `init` від `ScreenFactory`. Конкретні типи створюються лише у `SaifuApp`.
- Чесне застереження: ViewModel напряму використовують `CashWallet`, `ExpenseBuilder` і `AppRouter`. У кожного з них єдина реалізація, тож абстракція над ними була б штучною.

## Як замінити джерела без зміни ViewModel

Усі залежності обираються в `Saifu/App/SaifuApp.swift`.

**Репозиторій.** Демо-дані замість порожнього старту (або навпаки):

```swift
// порожній старт
ScreenFactory(repository: InMemoryWalletRepository(), ...)

// дані демо-сценарію (гаманці JPY і UAH)
ScreenFactory(repository: DemoWalletRepository(), ...)
```

**Джерело курсів.** Достатньо написати тип, що реалізує `NBURecordSource`, і підставити його в адаптер:

```swift
struct NBUAPIRecordSource: NBURecordSource {
    func records() async throws -> [NBURecord] {
        // запит до API НБУ і декодування [NBURecord]
    }
}

// SaifuApp
rateProvider: NBURateAdapter(source: NBUAPIRecordSource())
```

`NBURecord` уже `Decodable`, а `ExchangeRateProvider` вже асинхронний, тому `WalletViewModel` лишається без змін.

## Таблиця: патерн / принцип, компонент, призначення

| Патерн / принцип | Компонент | Призначення |
|---|---|---|
| MVVM | п'ять пар View / ViewModel, моделі | Розділення показу, стану екрана й домену |
| Router | `AppRouter`, `Route`, `Sheet`, `RootView` | Усі переходи в одному місці, View не керують навігацією |
| Factory | `ScreenFactory` | Створення екранів і їхніх ViewModel із залежностей кореня |
| Observer | `@Observable CashWallet` | Усі екрани бачать один стан гаманця |
| Repository | `WalletRepository`, `InMemoryWalletRepository`, `DemoWalletRepository` | Джерело гаманців, яке можна підміняти |
| Builder | `ExpenseBuilder` | Збирання і валідація `Expense` з введення форми |
| Strategy | `CategorySuggestionStrategy`, `KeywordCategoryStrategy`, `LastUsedCategoryStrategy` | Взаємозамінні способи підказати категорію |
| Composite (за роллю) | `ChainedCategoryStrategy` | Кілька стратегій як одна |
| Adapter | `NBURateAdapter` | Формат НБУ → `ExchangeRate` |
| Composition root | `SaifuApp` | Єдине місце створення залежностей |
| S | `ExpenseBuilder`, `NBURateAdapter`, `EntryRow` | Кожен тип має одну задачу |
| O | `CategoryDictionaries` | Новий словник без змін класів |
| L | реалізації протоколів репозиторію, стратегії, курсів | Підстановка без змін ViewModel |
| I | `NBURecordSource`, `learn` зі стандартною реалізацією | Вузькі інтерфейси |
| D | усі ViewModel | Залежність від протоколів, а не від конкретних типів |

## Антипатерни: було → стало

Перевірка коду на антипатерни дала такі виправлення (коміт «Fix antipatterns found in architecture review»).

| Що | Було | Стало |
|---|---|---|
| Надмірна відповідальність | `WalletViewModel` сам збирав рядки операцій (заголовок, емодзі, знак, текст суми) двома блоками майже однакового коду | Рядки будують `EntryRow.init(topUp:currency:)` та `EntryRow.init(expense:currency:)` у `ViewModels/EntryRow.swift`, ViewModel лише викликає їх |
| UI з прямим доступом до даних | `WalletViewModel.wallets` та `selectedWallet` були доступні ззовні, тож `View` міг дістатися до `CashWallet` | Обидві властивості `private`, `View` бачить лише `walletNames`, `balanceText`, `rows` та інший готовий стан |
| Дублювання | Злиття словників `english` та `ukrainian` повторювалось у `SaifuApp` і в `#Preview` | Одне місце: `CategoryDictionaries.all` |
| Прихована залежність | `DemoWalletRepository.init()` всередині викликав `DemoScenario.run()`, залежність не було видно в сигнатурі | `init(wallets: [CashWallet] = DemoScenario.run())`: залежність явна, її можна замінити |

**Чого в коді немає і чому.**
- **Синглтони та змінний статичний стан** відсутні. Статичні значення (`CategoryDictionaries`, форматувальник дати в `NBURateAdapter`) є незмінними константами. `DemoScenario.run()` — статична функція без стану, вона лише будує й повертає дані.
- **Прямий доступ UI до даних.** Кожен View бачить тільки свою ViewModel.

**Що свідомо залишено.**
- `CashWallet.formattedBalance` та `expenseSummaries()` повертають відформатовані рядки, тобто презентація лишилась у доменній моделі. Умова лаби 2 забороняє переписувати моделі, а ці методи документовані у README лаби 1 як демонстрація конструкцій Swift.
- Цикл піднесення 10 до степеня `minorUnits` повторюється в `Currency.format`, `parseMinor` та `inputText`. Тепер усі три копії в одному типі.
- `Date()` і `UUID()` використовуються як значення за замовчуванням у `Expense`, `CashTopUp`, `CashWallet` та `ExpenseBuilder`. Для тестів дату можна передати явно (`.date(_)`).
- `CashWallet` є посилальним типом, тому `repository.save` у `InMemoryWalletRepository` лише закріплює вже внесену зміну. З реальним сховищем (лаба 4 і далі) цей виклик стане суттєвим.
