import Foundation
import Observation

/// Вкладка перемикача гаманців.
struct WalletTab: Identifiable {
    let id: UUID
    let title: String
}

/// Головний екран. Стан обчислюється з @Observable CashWallet, тому оновлюється сам після змін на інших екранах.
@MainActor
@Observable
final class WalletViewModel {
    /// Скільки останніх операцій показувати на головному екрані.
    private static let recentLimit = 5

    private let rateProvider: any ExchangeRateProvider
    private let router: AppRouter
    private var rateTask: Task<Void, Never>?
    /// Курс валюти обраного гаманця; запитується лише при зміні гаманця.
    private var rate: ExchangeRate?

    private let wallets: [CashWallet]
    var selectedWalletID: UUID? {
        didSet { loadRate() }
    }

    init(repository: WalletRepository,
         rateProvider: any ExchangeRateProvider,
         router: AppRouter) {
        self.rateProvider = rateProvider
        self.router = router
        wallets = repository.wallets()
        selectedWalletID = wallets.first?.id
        loadRate()
    }

    /// Перемикач показує код валюти: JPY / UAH.
    var walletTabs: [WalletTab] {
        wallets.map { WalletTab(id: $0.id, title: $0.currency.code) }
    }

    private var selectedWallet: CashWallet? {
        wallets.first { $0.id == selectedWalletID }
    }

    var walletName: String {
        selectedWallet?.name ?? ""
    }

    var balanceText: String {
        selectedWallet?.formattedBalance ?? ""
    }

    /// Баланс у гривнях; nil для гривневого гаманця або поки курс не отримано.
    var convertedBalanceText: String? {
        guard let wallet = selectedWallet, wallet.currency != .uah,
              let rate, rate.currency == wallet.currency else { return nil }
        return "≈ " + Currency.uah.format(rate.toUAHMinor(wallet.expectedBalance))
    }

    /// Останні операції (витрати й поповнення разом), нові зверху.
    var recentRows: [EntryRow] {
        guard let wallet = selectedWallet else { return [] }
        let topUpRows = wallet.topUps.map { EntryRow(topUp: $0, currency: wallet.currency) }
        let expenseRows = wallet.expenses.map { EntryRow(expense: $0, currency: wallet.currency) }
        return (topUpRows + expenseRows)
            .sorted { $0.date > $1.date }
            .prefix(Self.recentLimit)
            .map { $0 }
    }

    func addExpenseTapped() {
        guard let wallet = selectedWallet else { return }
        router.presentAddExpense(walletID: wallet.id)
    }

    func reconcileTapped() {
        guard let wallet = selectedWallet else { return }
        router.presentReconcile(walletID: wallet.id)
    }

    func allExpensesTapped() {
        guard let wallet = selectedWallet else { return }
        router.showExpenseList(walletID: wallet.id)
    }

    /// Курс беремо асинхронно; застарілий запит скасовуємо при зміні гаманця.
    private func loadRate() {
        rateTask?.cancel()
        rate = nil
        guard let currency = selectedWallet?.currency, currency != .uah else { return }

        rateTask = Task {
            guard let rate = try? await rateProvider.rate(for: currency), !Task.isCancelled else { return }
            self.rate = rate
        }
    }
}
