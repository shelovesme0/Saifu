import Foundation
import Observation

/// Форма гаманця: новий (назва, валюта, початкова сума) або редагування наявного (назва, валюта без записів).
@MainActor
@Observable
final class WalletFormViewModel {
    private let repository: WalletRepository
    private let router: AppRouter
    /// nil — створюємо новий гаманець.
    private let wallet: CashWallet?

    var name = ""
    var currency: Currency = .jpy {
        // Для валюти без копійок (JPY) кома з уже введеної суми зникає
        didSet { initialAmountText = AmountInputFilter.sanitize(initialAmountText, currency: currency) }
    }
    var initialAmountText = ""
    private(set) var errorMessage: String?

    init(walletID: UUID?, repository: WalletRepository, router: AppRouter) {
        self.repository = repository
        self.router = router
        wallet = walletID.flatMap { repository.wallet(id: $0) }
        if let wallet {
            name = wallet.name
            currency = wallet.currency
        }
    }

    var isNew: Bool { wallet == nil }

    var title: String {
        isNew ? "Новий гаманець" : "Гаманець"
    }

    /// Валюту наявного гаманця можна змінити, лише поки в ньому немає записів.
    var canChangeCurrency: Bool {
        wallet?.hasNoEntries ?? true
    }

    var currencyHint: String? {
        canChangeCurrency ? nil : "У гаманці вже є записи, тому валюту змінити не можна"
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Вкажіть назву гаманця"
            return
        }
        do {
            if let wallet {
                wallet.name = trimmedName
                try wallet.changeCurrency(to: currency)
                repository.save(wallet)
            } else {
                let wallet = CashWallet(name: trimmedName, currency: currency)
                if !initialAmountText.isEmpty {
                    let amount = try currency.parseMinor(initialAmountText)
                    if amount > 0 {
                        // Початкова сума — звичайне поповнення
                        try wallet.addTopUp(CashTopUp(amount: amount, source: .atm))
                    }
                }
                repository.save(wallet)
            }
            errorMessage = nil
            router.popWallets()
        } catch {
            errorMessage = WalletError.message(for: error, fallback: "Не вдалося зберегти гаманець")
        }
    }
}
