import Foundation

/// Курс валюти до гривні: скільки гривень коштує 1 основна одиниця (1 ¥, 1 $, ...).
struct ExchangeRate {
    let currency: Currency
    let toUAH: Decimal
    let date: Date

    /// Переводить суму в найменших одиницях `currency` у копійки; без Double.
    func toUAHMinor(_ minor: Int) -> Int {
        var value = Decimal(minor) * toUAH
        value *= pow(10, Currency.uah.minorUnits)
        value /= pow(10, currency.minorUnits)

        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}
