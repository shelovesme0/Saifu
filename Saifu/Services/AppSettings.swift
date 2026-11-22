import Foundation
import Observation

/// Спільні налаштування застосунку. @Observable, тож зміна домашньої валюти одразу оновлює всі екрани.
/// Значення зберігається в UserDefaults під тим самим ключем, що його прочитає лаба 4.
@MainActor
@Observable
final class AppSettings {
    static let homeCurrencyKey = "homeCurrency"

    @ObservationIgnored private let defaults: UserDefaults

    var homeCurrency: Currency {
        didSet { defaults.set(homeCurrency.rawValue, forKey: Self.homeCurrencyKey) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        // За замовчуванням — гривня
        homeCurrency = defaults.string(forKey: Self.homeCurrencyKey).flatMap(Currency.init(rawValue:)) ?? .uah
    }
}
