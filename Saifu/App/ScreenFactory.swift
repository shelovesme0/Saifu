import SwiftUI

/// Створює екрани з їхніми ViewModel. Залежності отримує від SaifuApp і більше ніде їх не створює.
@MainActor
final class ScreenFactory {
    let router: AppRouter
    /// Кореневі екрани вкладок живуть весь час роботи застосунку, тому їхні ViewModel по одній.
    let walletViewModel: WalletViewModel
    let analyticsViewModel: AnalyticsViewModel
    let settingsViewModel: SettingsViewModel
    private let repository: WalletRepository

    init(repository: WalletRepository,
         categoryStrategy: any CategorySuggestionStrategy,
         rateProvider: any ExchangeRateProvider,
         reminderScheduler: any ReminderScheduling,
         defaults: UserDefaults,
         appVersion: String,
         router: AppRouter) {
        self.repository = repository
        self.router = router
        // Спільні для кількох екранів: домашня валюта і перерахунок курсів
        let settings = AppSettings(defaults: defaults)
        let converter = CurrencyConverter(rateProvider: rateProvider)
        walletViewModel = WalletViewModel(
            repository: repository,
            converter: converter,
            settings: settings,
            router: router,
            makeAddExpenseViewModel: { walletID in
                AddExpenseViewModel(walletID: walletID, repository: repository, categoryStrategy: categoryStrategy)
            }
        )
        analyticsViewModel = AnalyticsViewModel(
            repository: repository,
            converter: converter,
            settings: settings,
            router: router
        )
        settingsViewModel = SettingsViewModel(
            settings: settings,
            router: router,
            scheduler: reminderScheduler,
            defaults: defaults,
            appVersion: appVersion
        )
    }

    /// Дії при запуску застосунку (переплановування нагадувань).
    func appDidLaunch() async {
        await settingsViewModel.appDidLaunch()
    }

    // MARK: - Кореневі екрани вкладок

    func homeView() -> some View {
        WalletView(viewModel: walletViewModel)
    }

    func analyticsView() -> some View {
        AnalyticsView(viewModel: analyticsViewModel)
    }

    func settingsView() -> some View {
        SettingsView(viewModel: settingsViewModel)
    }

    // MARK: - Sheet «Гаманці»

    func walletsView() -> some View {
        WalletsView(viewModel: WalletsViewModel(repository: repository, router: router))
    }

    @ViewBuilder
    func view(for route: WalletsRoute) -> some View {
        switch route {
        case .addWallet:
            WalletFormView(viewModel: WalletFormViewModel(walletID: nil, repository: repository, router: router))
        case .editWallet(let walletID):
            WalletFormView(viewModel: WalletFormViewModel(walletID: walletID, repository: repository, router: router))
        }
    }

    // MARK: - Маршрути й sheet

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .expenseList(let walletID):
            ExpenseListView(viewModel: ExpenseListViewModel(
                walletID: walletID,
                repository: repository,
                router: router
            ))
        case .expenseDetail(let walletID, let expenseID):
            ExpenseDetailView(viewModel: ExpenseDetailViewModel(
                walletID: walletID,
                expenseID: expenseID,
                repository: repository,
                router: router
            ))
        }
    }

    @ViewBuilder
    func view(for sheet: Sheet) -> some View {
        switch sheet {
        case .reconcile(let walletID):
            ReconcileView(viewModel: ReconcileViewModel(
                walletID: walletID,
                repository: repository,
                router: router
            ))
        case .wallets:
            WalletsSheet(factory: self)
        case .analyticsPeriod:
            // Та сама ViewModel, що й в аналітиці: sheet редагує її чернетку періоду
            AnalyticsPeriodView(viewModel: analyticsViewModel)
        }
    }
}

#if DEBUG
extension ScreenFactory {
    /// Залежності для #Preview (ті самі демо-дані, що й у застосунку; нагадування не плануються).
    static func preview() -> ScreenFactory {
        ScreenFactory(
            repository: DemoWalletRepository(),
            categoryStrategy: ChainedCategoryStrategy([
                LastUsedCategoryStrategy(),
                KeywordCategoryStrategy(dictionary: CategoryDictionaries.all)
            ]),
            rateProvider: NBURateAdapter(source: DemoNBURecordSource()),
            reminderScheduler: PreviewReminderScheduler(),
            defaults: UserDefaults(suiteName: "saifu.preview") ?? .standard,
            appVersion: "1.0 (preview)",
            router: AppRouter()
        )
    }

    /// Перший гаманець для превʼю екранів, які отримують ID.
    var previewWalletID: UUID {
        repository.wallets()[0].id
    }

    /// Перша витрата першого гаманця для превʼю деталей.
    var previewExpenseID: UUID {
        repository.wallets()[0].expenses[0].id
    }
}
#endif
