import SwiftUI

/// Sheet «Гаманці» зі своїм NavigationStack: список → форма додавання / редагування.
/// Як і RootView, лише прив'язує стан роутера до SwiftUI й питає ScreenFactory про екрани.
struct WalletsSheet: View {
    let factory: ScreenFactory
    @Bindable private var router: AppRouter

    init(factory: ScreenFactory) {
        self.factory = factory
        router = factory.router
    }

    var body: some View {
        NavigationStack(path: $router.walletsPath) {
            factory.walletsView()
                .navigationDestination(for: WalletsRoute.self) { route in
                    factory.view(for: route)
                }
        }
        .tint(Theme.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .presentationCornerRadius(Theme.bigCardRadius)
        .preferredColorScheme(.dark)
    }
}
