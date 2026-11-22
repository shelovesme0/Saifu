import Foundation
import Observation

/// Вкладки TabView.
enum AppTab: CaseIterable, Hashable {
    case home, analytics, settings
}

/// Екрани в стеку NavigationStack вкладки.
enum Route: Hashable {
    case expenseList(walletID: UUID)
    case expenseDetail(walletID: UUID, expenseID: UUID)
}

/// Модальні екрани (sheet).
enum Sheet: Identifiable, Hashable {
    case reconcile(walletID: UUID)
    case wallets
    case analyticsPeriod

    var id: Self { self }
}

/// Екрани всередині sheet «Гаманці».
enum WalletsRoute: Hashable {
    case addWallet
    case editWallet(walletID: UUID)
}

/// Єдине місце, де змінюється навігація. Методи викликають ViewModel, а не екрани.
@MainActor
@Observable
final class AppRouter {
    /// Binding для TabView(selection:).
    var selectedTab: AppTab = .home
    /// Окремий стек для кожної вкладки.
    var homePath: [Route] = []
    var analyticsPath: [Route] = []
    var settingsPath: [Route] = []
    var sheet: Sheet?
    /// Стек усередині sheet «Гаманці» (додавання, редагування).
    var walletsPath: [WalletsRoute] = []

    func showExpenseList(walletID: UUID) {
        selectedTab = .home
        homePath.append(.expenseList(walletID: walletID))
    }

    func showExpenseDetail(walletID: UUID, expenseID: UUID) {
        selectedTab = .home
        homePath.append(.expenseDetail(walletID: walletID, expenseID: expenseID))
    }

    /// Повернення на попередній екран стеку поточної вкладки.
    func pop() {
        switch selectedTab {
        case .home: if !homePath.isEmpty { homePath.removeLast() }
        case .analytics: if !analyticsPath.isEmpty { analyticsPath.removeLast() }
        case .settings: if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }

    func presentReconcile(walletID: UUID) {
        sheet = .reconcile(walletID: walletID)
    }

    /// Sheet «Гаманці» — з головної й з налаштувань.
    func presentWallets() {
        walletsPath = []
        sheet = .wallets
    }

    func showAddWallet() {
        walletsPath.append(.addWallet)
    }

    func showEditWallet(walletID: UUID) {
        walletsPath.append(.editWallet(walletID: walletID))
    }

    /// Назад у списку гаманців (після збереження форми).
    func popWallets() {
        if !walletsPath.isEmpty { walletsPath.removeLast() }
    }

    func presentAnalyticsPeriod() {
        sheet = .analyticsPeriod
    }

    func dismissSheet() {
        sheet = nil
        walletsPath = []
    }
}
