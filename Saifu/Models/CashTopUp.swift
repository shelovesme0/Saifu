import Foundation

/// Звідки взялося поповнення.
enum TopUpSource {
    case atm
    /// Коригувальне поповнення при надлишку під час звірки.
    case correction
}

/// Поповнення гаманця (наприклад, знята готівка в банкоматі).
struct CashTopUp: WalletEntry {
    let id: UUID
    var amount: Int
    let date: Date
    let source: TopUpSource

    var signedAmount: Int { amount }

    init(id: UUID = UUID(), amount: Int, date: Date = Date(), source: TopUpSource = .atm) {
        self.id = id
        self.amount = amount
        self.date = date
        self.source = source
    }
}
