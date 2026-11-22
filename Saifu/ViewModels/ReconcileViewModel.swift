import Foundation
import Observation

/// Звірка: користувач вводить реальну готівку, бачить різницю й підтверджує.
@MainActor
@Observable
final class ReconcileViewModel {
    /// Знак різниці для кольору в UI.
    enum Outcome {
        case shortage, surplus, match
    }

    private let wallet: CashWallet?
    private let repository: WalletRepository
    private let router: AppRouter

    var actualText = ""
    private(set) var errorMessage: String?

    init(walletID: UUID, repository: WalletRepository, router: AppRouter) {
        self.repository = repository
        self.router = router
        wallet = repository.wallet(id: walletID)
    }

    var walletTitle: String {
        guard let wallet else { return "" }
        return "\(wallet.name) · \(wallet.currency.code)"
    }

    var currency: Currency {
        wallet?.currency ?? .uah
    }

    var expectedText: String {
        wallet?.formattedBalance ?? ""
    }

    /// Попередній результат без зміни гаманця; nil, поки введення не розпізнано.
    private var preview: Reconciliation? {
        guard let wallet,
              let actual = try? wallet.currency.parseMinor(actualText),
              actual >= 0 else { return nil }
        return Reconciliation(expected: wallet.expectedBalance, actual: actual)
    }

    var outcome: Outcome? {
        guard let difference = preview?.difference else { return nil }
        // switch по знаку різниці, як у CashWallet.reconcile
        switch difference {
        case 1...: return .shortage
        case ..<0: return .surplus
        default: return .match
        }
    }

    var differenceText: String? {
        guard let wallet, let difference = preview?.difference, let outcome else { return nil }
        let amount = wallet.currency.format(abs(difference))
        switch outcome {
        case .shortage: return "Недостача \(amount) буде записана як «\(ExpenseCategory.untracked.title)»"
        case .surplus: return "Надлишок \(amount) буде записаний як коригувальне поповнення"
        case .match: return "Баланс збігся, нічого не буде записано"
        }
    }

    /// Короткий текст бейджа: "Сходиться", "Недостача 500 ¥", "Надлишок 200 ¥".
    var badgeTitle: String? {
        guard let wallet, let difference = preview?.difference, let outcome else { return nil }
        let amount = wallet.currency.format(abs(difference))
        switch outcome {
        case .shortage: return "Недостача \(amount)"
        case .surplus: return "Надлишок \(amount)"
        case .match: return "Сходиться"
        }
    }

    func confirm() {
        guard let wallet else {
            errorMessage = "Гаманець не знайдено"
            return
        }
        do {
            let actual = try wallet.currency.parseMinor(actualText)
            try wallet.reconcile(actualCash: actual)
            repository.save(wallet)
            errorMessage = nil
            router.dismissSheet()
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося звірити гаманець")
        }
    }

    func cancel() {
        router.dismissSheet()
    }
}
