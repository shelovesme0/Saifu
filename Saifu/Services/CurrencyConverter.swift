import Foundation
import Observation

/// Перераховує суми між валютами крос-курсом через гривню (курси НБУ задані до гривні).
/// Курси завантажуються один раз; екрани оновлюються, щойно вони надійдуть.
@MainActor
@Observable
final class CurrencyConverter {
    @ObservationIgnored private let rateProvider: any ExchangeRateProvider
    private var rates: [Currency: ExchangeRate] = [:]

    init(rateProvider: any ExchangeRateProvider) {
        self.rateProvider = rateProvider
        loadRates()
    }

    /// Сума `minor` у валюті `from` → найменші одиниці `to`; nil, поки потрібного курсу немає.
    func convert(_ minor: Int, from: Currency, to: Currency) -> Int? {
        if from == to { return minor }

        let uahMinor: Int
        if from == .uah {
            uahMinor = minor
        } else {
            guard let rate = rates[from] else { return nil }
            uahMinor = rate.toUAHMinor(minor)
        }

        if to == .uah { return uahMinor }
        guard let rate = rates[to] else { return nil }
        return rate.fromUAHMinor(uahMinor)
    }

    /// "≈ 4 077,00 ₴"; nil, якщо валюти збігаються або курсу ще немає.
    func approximateText(_ minor: Int, from: Currency, to: Currency) -> String? {
        guard from != to, let converted = convert(minor, from: from, to: to) else { return nil }
        return "≈ " + to.format(converted)
    }

    private func loadRates() {
        for currency in Currency.allCases where currency != .uah {
            Task {
                guard let rate = try? await rateProvider.rate(for: currency) else { return }
                rates[currency] = rate
            }
        }
    }
}
