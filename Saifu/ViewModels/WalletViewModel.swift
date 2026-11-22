import Foundation
import Observation

/// Головний екран. Стан обчислюється з @Observable CashWallet, тому оновлюється сам після змін на інших екранах.
@MainActor
@Observable
final class WalletViewModel {
    private let rateProvider: any ExchangeRateProvider
    private let router: AppRouter
    private var rateTask: Task<Void, Never>?
    /// Курс валюти обраного гаманця; запитується лише при зміні гаманця.
    private var rate: ExchangeRate?

    private let wallets: [CashWallet]
    var selectedIndex = 0 {
        didSet { loadRate() }
    }

    init(repository: WalletRepository,
         rateProvider: any ExchangeRateProvider,
         router: AppRouter) {
        self.rateProvider = rateProvider
        self.router = router
        wallets = repository.wallets()
        loadRate()
    }

    var walletNames: [String] {
        wallets.map(\.name)
    }

    private var selectedWallet: CashWallet? {
        wallets.indices.contains(selectedIndex) ? wallets[selectedIndex] : nil
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

    var rows: [EntryRow] {
        guard let wallet = selectedWallet else { return [] }
        let topUpRows = wallet.topUps.map { EntryRow(topUp: $0, currency: wallet.currency) }
        let expenseRows = wallet.expenses.map { EntryRow(expense: $0, currency: wallet.currency) }
        return topUpRows + expenseRows
    }

    func addExpenseTapped() {
        guard let wallet = selectedWallet else { return }
        router.presentAddExpense(walletID: wallet.id)
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
