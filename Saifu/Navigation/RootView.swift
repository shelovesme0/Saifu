import SwiftUI

/// Корінь навігації: прив'язує стан роутера до NavigationStack і sheet.
struct RootView: View {
    let factory: ScreenFactory
    @Bindable private var router: AppRouter

    init(factory: ScreenFactory) {
        self.factory = factory
        router = factory.router
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            WalletView(viewModel: factory.walletViewModel)
                .navigationDestination(for: Route.self) { route in
                    factory.view(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            factory.view(for: sheet)
        }
    }
}

#Preview {
    RootView(factory: .preview())
}
