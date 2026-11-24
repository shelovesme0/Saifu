import Foundation

/// Записи НБУ з API: `GET https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?valcode=<CODE>&json`.
/// Для кожної валюти окремий запит; запити йдуть паралельно.
struct NBURemoteRecordSource: NBURecordSource {
    static let baseURL = URL(string: "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange")!

    private let client: HTTPClient
    private let currencies: [Currency]
    /// nil — курс на сьогодні; інакше курс на вказану дату.
    private let date: Date?

    init(client: HTTPClient,
         currencies: [Currency] = Currency.allCases.filter { $0 != .uah },
         date: Date? = nil) {
        self.client = client
        self.currencies = currencies
        self.date = date
    }

    func records() async throws -> [NBURecord] {
        let client = client
        let urls = currencies.map(url(for:))
        let records = try await withThrowingTaskGroup(of: [NBURateDTO].self) { group in
            for url in urls {
                group.addTask { try await client.get(url) }
            }
            var result: [NBURecord] = []
            for try await dtos in group {
                result += dtos.map(\.record)
            }
            return result
        }
        // НБУ на невідомий код чи дату без курсу відповідає 200 і `[]` — це не помилка сервера, а «даних немає»
        guard !records.isEmpty else { throw NetworkError.empty }
        return records
    }

    /// `…/exchange?valcode=JPY&date=20261124&json`
    func url(for currency: Currency) -> URL {
        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "valcode", value: currency.code)]
        if let date {
            items.append(URLQueryItem(name: "date", value: Self.dateFormatter.string(from: date)))
        }
        // Без `json` API віддає XML
        items.append(URLQueryItem(name: "json", value: nil))
        components.queryItems = items
        return components.url!
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
