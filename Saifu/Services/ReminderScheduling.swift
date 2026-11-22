import Foundation

/// Як часто нагадувати звірити гаманець.
enum ReminderInterval: Int, CaseIterable, Hashable {
    case daily = 1
    case everyThreeDays = 3
    case weekly = 7

    var days: Int { rawValue }

    var title: String {
        switch self {
        case .daily: return "Щодня"
        case .everyThreeDays: return "Раз на 3 дні"
        case .weekly: return "Щотижня"
        }
    }
}

/// Час доби, коли приходить нагадування.
struct ReminderTime: Equatable {
    var hour: Int
    var minute: Int

    static let defaultTime = ReminderTime(hour: 20, minute: 0)
}

/// Планування нагадувань про звірку. Реалізацію отримує SettingsViewModel через init.
protocol ReminderScheduling {
    /// Запитує дозвіл на сповіщення; true, якщо дозволено.
    func requestAuthorization() async -> Bool
    /// Планує нагадування з інтервалом на вказаний час (попередні замінюються).
    func schedule(every interval: ReminderInterval, at time: ReminderTime) async
    /// Скасовує всі заплановані нагадування.
    func cancel()
}
