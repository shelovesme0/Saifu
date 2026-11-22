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
        NavigationStack {
            WalletView(viewModel: factory.walletViewModel)
        }
        .sheet(item: $router.sheet) { sheet in
            factory.view(for: sheet)
        }
    }
}

#Preview {
    RootView(factory: .preview())
}
