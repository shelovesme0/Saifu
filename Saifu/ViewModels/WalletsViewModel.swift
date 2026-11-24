import Foundation
import Observation

/// Рядок гаманця у списку керування.
struct WalletSummary: Identifiable, Equatable {
    let id: UUID
    let title: String
    let currencyCode: String
    let balanceText: String
    let isNegative: Bool
}

/// Sheet «Гаманці»: список, порядок, видалення; додавання й редагування — окремі форми.
@MainActor
@Observable
final class WalletsViewModel {
    private let repository: WalletRepository
    private let router: AppRouter
    /// Текст помилки збереження (видалення чи порядок не записалися на пристрій).
    private(set) var errorMessage: String?

    init(repository: WalletRepository, router: AppRouter) {
        self.repository = repository
        self.router = router
    }

    var wallets: [WalletSummary] {
        repository.wallets().map {
            WalletSummary(id: $0.id,
                          title: $0.name,
                          currencyCode: $0.currency.code,
                          balanceText: $0.formattedBalance,
                          isNegative: $0.expectedBalance < 0)
        }
    }

    /// Останній гаманець видалити не можна.
    var canDelete: Bool {
        repository.wallets().count > 1
    }

    func addTapped() {
        router.showAddWallet()
    }

    func walletTapped(_ wallet: WalletSummary) {
        router.showEditWallet(walletID: wallet.id)
    }

    func delete(id: UUID) {
        guard canDelete else { return }
        do {
            try repository.remove(id: id)
            errorMessage = nil
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося видалити гаманець")
        }
    }

    /// Порядок зберігається в репозиторії, тож свайп-картки й меню аналітики змінюються одразу.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        do {
            try repository.move(fromOffsets: source, toOffset: destination)
            errorMessage = nil
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося змінити порядок гаманців")
        }
    }

    func doneTapped() {
        router.dismissSheet()
    }
}
