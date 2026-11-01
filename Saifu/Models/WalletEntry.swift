import Foundation

/// Запис у гаманці (витрата або поповнення), щоб баланс рахувався однаково по всіх записах.
protocol WalletEntry: Identifiable where ID == UUID {
    /// Сума в найменших одиницях валюти гаманця, завжди додатна.
    var amount: Int { get }
    var date: Date { get }
    /// Витрата — мінус, поповнення — плюс.
    var signedAmount: Int { get }
}
