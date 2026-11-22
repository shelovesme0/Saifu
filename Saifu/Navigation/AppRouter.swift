import Foundation
import Observation

/// Екрани в стеку NavigationStack.
enum Route: Hashable {
    case expenseList(walletID: UUID)
    case expenseDetail(walletID: UUID, expenseID: UUID)
}

/// Модальні екрани (sheet).
enum Sheet: Identifiable, Hashable {
    case addExpense(walletID: UUID)
    case reconcile(walletID: UUID)

    var id: Self { self }
}

/// Єдине місце, де змінюється навігація. Методи викликають ViewModel, а не View.
@MainActor
@Observable
final class AppRouter {
    var path: [Route] = []
    var sheet: Sheet?

    func showExpenseList(walletID: UUID) {
        path.append(.expenseList(walletID: walletID))
    }

    func showExpenseDetail(walletID: UUID, expenseID: UUID) {
        path.append(.expenseDetail(walletID: walletID, expenseID: expenseID))
    }

    /// Повернення на попередній екран стеку (після збереження чи видалення).
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func presentAddExpense(walletID: UUID) {
        sheet = .addExpense(walletID: walletID)
    }

    func presentReconcile(walletID: UUID) {
        sheet = .reconcile(walletID: walletID)
    }

    func dismissSheet() {
        sheet = nil
    }
}
