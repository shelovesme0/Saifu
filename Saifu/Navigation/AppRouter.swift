import Foundation
import Observation

/// Модальні екрани (sheet).
enum Sheet: Identifiable, Hashable {
    case addExpense(walletID: UUID)

    var id: Self { self }
}

/// Єдине місце, де змінюється навігація. Методи викликають ViewModel, а не View.
@MainActor
@Observable
final class AppRouter {
    var sheet: Sheet?

    func presentAddExpense(walletID: UUID) {
        sheet = .addExpense(walletID: walletID)
    }

    func dismissSheet() {
        sheet = nil
    }
}
