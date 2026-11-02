import Foundation

/// Адаптер: перетворює записи формату НБУ на `ExchangeRate`.
struct NBURateAdapter: ExchangeRateProvider {
    private let source: NBURecordSource

    init(source: NBURecordSource) {
        self.source = source
    }

    func rate(for currency: Currency) async throws -> ExchangeRate? {
        let records = try await source.records()
        guard let record = records.first(where: { $0.cc.uppercased() == currency.code }) else { return nil }
        return adapt(record)
    }

    /// nil, якщо код валюти невідомий застосунку або дату не вдалося розібрати.
    func adapt(_ record: NBURecord) -> ExchangeRate? {
        guard let currency = Currency(rawValue: record.cc.lowercased()),
              let date = Self.dateFormatter.date(from: record.exchangedate) else { return nil }
        return ExchangeRate(currency: currency, toUAH: record.rate, date: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}
