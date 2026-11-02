import Foundation

/// Джерело курсів. `async throws` вже зараз, щоб реальний API у лабі 4 не змінював ViewModel.
protocol ExchangeRateProvider {
    func rate(for currency: Currency) async throws -> ExchangeRate?
}
