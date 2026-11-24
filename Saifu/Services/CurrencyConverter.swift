import Foundation
import Observation

/// Перераховує суми між валютами крос-курсом через гривню (курси НБУ задані до гривні).
/// Тримає стан завантаження курсів для UI. Мережу сам не викликає — лише `ExchangeRateProvider`.
@MainActor
@Observable
final class CurrencyConverter {
    @ObservationIgnored private let rateProvider: any ExchangeRateProvider
    @ObservationIgnored private let cache: (any RateCacheInvalidating)?
    @ObservationIgnored private let now: () -> Date
    private var rates: [Currency: ExchangeRate] = [:]
    /// День, за який завантажено курси; на інший день `loadIfNeeded()` завантажить знову.
    @ObservationIgnored private var loadedDay: DateComponents?
    /// Номер завантаження: відповідь застарілого запиту не перезаписує новіший стан.
    @ObservationIgnored private var loadID = 0

    private(set) var state: LoadState = .idle

    init(rateProvider: any ExchangeRateProvider,
         cache: (any RateCacheInvalidating)? = nil,
         now: @escaping () -> Date = Date.init) {
        self.rateProvider = rateProvider
        self.cache = cache
        self.now = now
    }

    // MARK: - Завантаження

    /// При запуску й поверненні на передній план: нічого не робить, якщо курси за сьогодні вже є.
    func loadIfNeeded() async {
        if state == .loading { return }
        if state == .loaded, loadedDay == today { return }
        await load()
    }

    /// Pull-to-refresh, «Повторити», зміна джерела: скидає кеш і завантажує знову.
    func reload() async {
        cache?.invalidate()
        await load()
    }

    private func load() async {
        loadID += 1
        let id = loadID
        state = .loading

        var loaded: [Currency: ExchangeRate] = [:]
        do {
            // Мережа — лише при першому виклику: CachedRecordSource віддає решті валют те саме завантаження
            for currency in Currency.allCases where currency != .uah {
                loaded[currency] = try await rateProvider.rate(for: currency)
            }
        } catch {
            guard id == loadID, !Self.isCancellation(error) else { return }
            rates = [:]
            state = LoadState.from(error)
            return
        }

        guard id == loadID else { return }
        if loaded.isEmpty {
            rates = [:]
            state = .empty
            return
        }
        rates = loaded
        loadedDay = today
        state = .loaded
    }

    private var today: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: now())
    }

    /// Екран закрили під час pull-to-refresh — це не помилка для користувача.
    private static func isCancellation(_ error: any Error) -> Bool {
        if error is CancellationError { return true }
        if case .transport(let urlError) = error as? NetworkError, urlError.code == .cancelled { return true }
        return false
    }

    // MARK: - Перерахунок

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

    /// "1 ¥ = 0,28336 ₴ · НБУ, 24.11.2026"; nil, якщо курсу немає.
    func rateText(from: Currency, to: Currency) -> String? {
        guard from != to, let value = crossRate(from: from, to: to) else { return nil }
        let number = Self.rateFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        var text = "1 \(from.symbol) = \(number) \(to.symbol)"
        // Дата курсу — з тієї валюти, що не гривня
        if let date = (rates[from] ?? rates[to])?.date {
            text += " · НБУ, " + Self.dateFormatter.string(from: date)
        }
        return text
    }

    /// Скільки одиниць `to` за 1 одиницю `from` (через гривню, у Decimal).
    private func crossRate(from: Currency, to: Currency) -> Decimal? {
        let fromUAH: Decimal? = from == .uah ? 1 : rates[from]?.toUAH
        let toUAH: Decimal? = to == .uah ? 1 : rates[to]?.toUAH
        guard let fromUAH, let toUAH, toUAH > 0 else { return nil }
        return fromUAH / toUAH
    }

    private static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 5
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}
