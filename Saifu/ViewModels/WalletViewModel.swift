import Foundation
import Observation

/// Картка гаманця на головному екрані, уже готова для показу.
struct WalletCard: Identifiable, Equatable {
    let id: UUID
    /// "Єни · JPY"
    let title: String
    let balanceText: String
    /// "≈ …" у домашній валюті; nil, якщо валюта гаманця збігається з домашньою або курсу ще немає.
    let convertedText: String?
    /// Курс ще завантажується: замість «≈ …» показується ProgressView.
    let isRateLoading: Bool
    let isNegative: Bool
}

/// Рядок курсу під картками для обраного гаманця.
struct RateStatus: Equatable {
    let state: LoadState
    /// "1 ¥ = 0,28336 ₴ · НБУ, 24.11.2026", коли курс є.
    let rateText: String?
}

/// Головний екран. Стан обчислюється з @Observable репозиторію й гаманців,
/// тому оновлюється сам після змін на інших екранах (нові гаманці, витрати, звірка, домашня валюта).
@MainActor
@Observable
final class WalletViewModel {
    /// Скільки останніх витрат показувати на головному екрані.
    private static let recentLimit = 5

    private let repository: WalletRepository
    private let converter: CurrencyConverter
    private let settings: AppSettings
    private let router: AppRouter
    private let makeAddExpenseViewModel: (UUID) -> AddExpenseViewModel
    /// Форма додавання для кожного гаманця своя, щоб введене не губилося при свайпі.
    private var addExpenseViewModels: [UUID: AddExpenseViewModel] = [:]

    var selectedWalletID: UUID?

    init(repository: WalletRepository,
         converter: CurrencyConverter,
         settings: AppSettings,
         router: AppRouter,
         makeAddExpenseViewModel: @escaping (UUID) -> AddExpenseViewModel) {
        self.repository = repository
        self.converter = converter
        self.settings = settings
        self.router = router
        self.makeAddExpenseViewModel = makeAddExpenseViewModel
        selectedWalletID = repository.wallets().first?.id
    }

    private var wallets: [CashWallet] {
        repository.wallets()
    }

    /// Обраний гаманець; якщо його видалили — перший наявний.
    private var selectedWallet: CashWallet? {
        wallets.first { $0.id == selectedWalletID } ?? wallets.first
    }

    /// Викликається, коли змінився набір гаманців: виправляє вибір, якщо обраний зник.
    func walletsChanged() {
        if !wallets.contains(where: { $0.id == selectedWalletID }) {
            selectedWalletID = wallets.first?.id
        }
        addExpenseViewModels = addExpenseViewModels.filter { id, _ in wallets.contains { $0.id == id } }
    }

    /// Після імпорту копії: гаманці — нові екземпляри навіть з тими самими id,
    /// тому форми додавання (тримали старі) створюються наново, а вибір — перший гаманець.
    func dataReplaced() {
        addExpenseViewModels = [:]
        selectedWalletID = wallets.first?.id
    }

    /// Привітання за часом доби.
    var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Добрий ранок"
        case 12..<18: return "Добрий день"
        default: return "Добрий вечір"
        }
    }

    var cards: [WalletCard] {
        let home = settings.homeCurrency
        return wallets.map { wallet in
            WalletCard(id: wallet.id,
                       title: "\(wallet.name) · \(wallet.currency.code)",
                       balanceText: wallet.formattedBalance,
                       convertedText: converter.approximateText(wallet.expectedBalance, from: wallet.currency, to: home),
                       isRateLoading: wallet.currency != home && converter.state == .loading,
                       isNegative: wallet.expectedBalance < 0)
        }
    }

    // MARK: - Курс

    /// nil, якщо гаманця немає або його валюта збігається з домашньою (курс не потрібен).
    var rateStatus: RateStatus? {
        guard let wallet = selectedWallet, wallet.currency != settings.homeCurrency else { return nil }
        return RateStatus(state: converter.state,
                          rateText: converter.rateText(from: wallet.currency, to: settings.homeCurrency))
    }

    /// Pull-to-refresh: курс завантажується наново, навіть якщо на сьогодні вже є.
    func refreshRates() async {
        await converter.reload()
    }

    func retryRatesTapped() {
        Task { await converter.reload() }
    }

    var selectedIndex: Int {
        wallets.firstIndex { $0.id == selectedWallet?.id } ?? 0
    }

    /// Форма швидкого додавання для обраного гаманця.
    var addExpenseViewModel: AddExpenseViewModel? {
        guard let id = selectedWallet?.id else { return nil }
        if let existing = addExpenseViewModels[id] {
            return existing
        }
        let created = makeAddExpenseViewModel(id)
        addExpenseViewModels[id] = created
        return created
    }

    /// Останні витрати обраного гаманця, нові зверху.
    var recentRows: [EntryRow] {
        guard let wallet = selectedWallet else { return [] }
        return wallet.expenses
            .sorted { $0.date > $1.date }
            .prefix(Self.recentLimit)
            .map { EntryRow(expense: $0, currency: wallet.currency) }
    }

    /// false на першому запуску: замість карток показується порожній стан.
    var hasWallets: Bool {
        !wallets.isEmpty
    }

    /// Порожній стан → наявна форма нового гаманця в sheet «Гаманці».
    func createFirstWalletTapped() {
        router.presentWallets()
        router.showAddWallet()
    }

    func manageWalletsTapped() {
        router.presentWallets()
    }

    func reconcileTapped(walletID: UUID) {
        router.presentReconcile(walletID: walletID)
    }

    func rowTapped(_ row: EntryRow) {
        guard let wallet = selectedWallet, let expenseID = row.expenseID else { return }
        router.showExpenseDetail(walletID: wallet.id, expenseID: expenseID)
    }

    func allExpensesTapped() {
        guard let wallet = selectedWallet else { return }
        router.showExpenseList(walletID: wallet.id)
    }
}
