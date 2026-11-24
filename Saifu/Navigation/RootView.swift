import SwiftUI

/// Корінь навігації: нативний TabView з трьома вкладками, у кожної свій NavigationStack; sheet.
/// На iOS 26 система сама малює Liquid Glass-панель і анімацію вибору.
struct RootView: View {
    let factory: ScreenFactory
    @Bindable private var router: AppRouter
    /// Попередження про сховище; після «Зрозуміло» більше не показується.
    @State private var startupWarning: String?

    init(factory: ScreenFactory) {
        self.factory = factory
        router = factory.router
        _startupWarning = State(initialValue: factory.startupWarning)
    }

    var body: some View {
        tabView
            .tint(.white)
            .fontDesign(.rounded)
            .preferredColorScheme(.dark)
            .sheet(item: $router.sheet) { sheet in
                factory.view(for: sheet)
            }
            // Серію нагадувань «раз на 3 дні» поновлюємо при кожному запуску
            .task { await factory.appDidLaunch() }
            .alert("Дані недоступні",
                   isPresented: Binding(get: { startupWarning != nil },
                                        set: { if !$0 { startupWarning = nil } })) {
                Button("Зрозуміло", role: .cancel) {}
            } message: {
                Text(startupWarning ?? "")
            }
    }

    @ViewBuilder
    private var tabView: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $router.selectedTab) {
                Tab(AppTab.home.title, systemImage: AppTab.home.symbolName, value: AppTab.home) {
                    stack(path: $router.homePath) { factory.homeView() }
                }
                Tab(AppTab.analytics.title, systemImage: AppTab.analytics.symbolName, value: AppTab.analytics) {
                    stack(path: $router.analyticsPath) { factory.analyticsView() }
                }
                Tab(AppTab.settings.title, systemImage: AppTab.settings.symbolName, value: AppTab.settings) {
                    stack(path: $router.settingsPath) { factory.settingsView() }
                }
            }
            .minimizeTabBarOnScroll()
        } else {
            // iOS 17: старий API з .tabItem
            TabView(selection: $router.selectedTab) {
                stack(path: $router.homePath) { factory.homeView() }
                    .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.symbolName) }
                    .tag(AppTab.home)
                stack(path: $router.analyticsPath) { factory.analyticsView() }
                    .tabItem { Label(AppTab.analytics.title, systemImage: AppTab.analytics.symbolName) }
                    .tag(AppTab.analytics)
                stack(path: $router.settingsPath) { factory.settingsView() }
                    .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.symbolName) }
                    .tag(AppTab.settings)
            }
        }
    }

    private func stack<Content: View>(path: Binding<[Route]>,
                                      @ViewBuilder root: () -> Content) -> some View {
        NavigationStack(path: path) {
            root()
                .navigationDestination(for: Route.self) { route in
                    factory.view(for: route)
                }
        }
    }
}

private extension View {
    /// На iOS 26+ панель вкладок згортається при прокручуванні вниз.
    @ViewBuilder
    func minimizeTabBarOnScroll() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

extension AppTab {
    var symbolName: String {
        switch self {
        case .home: return "house"
        case .analytics: return "chart.pie"
        case .settings: return "gearshape"
        }
    }

    var title: String {
        switch self {
        case .home: return "Головна"
        case .analytics: return "Аналітика"
        case .settings: return "Налаштування"
        }
    }
}

#Preview {
    RootView(factory: .preview())
}
