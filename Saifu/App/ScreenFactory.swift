import SwiftUI

/// Створює екрани з їхніми ViewModel. Залежності отримує від SaifuApp і більше ніде їх не створює.
@MainActor
final class ScreenFactory {
    let router: AppRouter
    /// Головний екран живе весь час роботи застосунку, тому його ViewModel одна.
    let walletViewModel: WalletViewModel
    private let repository: WalletRepository
    private let categoryStrategy: any CategorySuggestionStrategy

    init(repository: WalletRepository,
         categoryStrategy: any CategorySuggestionStrategy,
         rateProvider: any ExchangeRateProvider,
         router: AppRouter) {
        self.repository = repository
        self.categoryStrategy = categoryStrategy
        self.router = router
        walletViewModel = WalletViewModel(repository: repository, rateProvider: rateProvider, router: router)
    }

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
        case .addExpense(let walletID):
            AddExpenseView(viewModel: AddExpenseViewModel(
                walletID: walletID,
                repository: repository,
                categoryStrategy: categoryStrategy,
                router: router
            ))
        case .reconcile(let walletID):
            ReconcileView(viewModel: ReconcileViewModel(
                walletID: walletID,
                repository: repository,
                router: router
            ))
        }
    }
}

#if DEBUG
extension ScreenFactory {
    /// Залежності для #Preview (ті самі демо-дані, що й у застосунку).
    static func preview() -> ScreenFactory {
        ScreenFactory(
            repository: DemoWalletRepository(),
            categoryStrategy: ChainedCategoryStrategy([
                LastUsedCategoryStrategy(),
                KeywordCategoryStrategy(dictionary: CategoryDictionaries.all)
            ]),
            rateProvider: NBURateAdapter(source: DemoNBURecordSource()),
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
