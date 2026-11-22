import Foundation
import UserNotifications

/// Локальні сповіщення «Пора звірити гаманець» через UNUserNotificationCenter.
/// - щодня / щотижня — один повторюваний календарний тригер;
/// - раз на 3 дні — серія одноразових нагадувань наперед (календар не вміє «кожні 3 дні»),
///   яку застосунок переплановує при запуску й при зміні налаштувань.
struct LocalReminderScheduler: ReminderScheduling {
    private static let prefix = "saifu.reminder."
    private static let dailyID = prefix + "daily"
    private static let weeklyID = prefix + "weekly"
    private static let seriesPrefix = prefix + "every3."
    /// Скільки найближчих нагадувань «раз на 3 дні» тримати запланованими (~місяць).
    private static let seriesCount = 10

    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let now: () -> Date

    init(center: UNUserNotificationCenter, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.center = center
        self.calendar = calendar
        self.now = now
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func schedule(every interval: ReminderInterval, at time: ReminderTime) async {
        // Уже заплановані нагадування — щоб зберегти день тижня й ритм «раз на 3 дні»
        let pending = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(Self.prefix) }

        let requests: [UNNotificationRequest]
        switch interval {
        case .daily:
            let components = DateComponents(hour: time.hour, minute: time.minute)
            requests = [request(id: Self.dailyID, components: components, repeats: true)]

        case .weekly:
            // День тижня — той, коли нагадування ввімкнули; при зміні часу він зберігається
            let weekday = pending
                .first { $0.identifier == Self.weeklyID }
                .flatMap { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents.weekday }
                ?? calendar.component(.weekday, from: now())
            let components = DateComponents(hour: time.hour, minute: time.minute, weekday: weekday)
            requests = [request(id: Self.weeklyID, components: components, repeats: true)]

        case .everyThreeDays:
            // Найближче з уже запланованих задає ритм серії; якщо серії немає — починаємо заново
            let anchor = pending
                .filter { $0.identifier.hasPrefix(Self.seriesPrefix) }
                .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
                .min()
            let first = firstSeriesDate(anchor: anchor, time: time, step: interval.days)
            requests = (0..<Self.seriesCount).compactMap { index in
                guard let date = calendar.date(byAdding: .day, value: index * interval.days, to: first) else { return nil }
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                return request(id: Self.seriesPrefix + String(index), components: components, repeats: false)
            }
        }

        cancel()
        for request in requests {
            try? await center.add(request)
        }
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: Self.allIDs)
    }

    // MARK: - Допоміжне

    private static var allIDs: [String] {
        [dailyID, weeklyID] + (0..<seriesCount).map { seriesPrefix + String($0) }
    }

    /// Перше нагадування серії в майбутньому: від дня якоря (з кроком `step`) або сьогодні/завтра.
    private func firstSeriesDate(anchor: Date?, time: ReminderTime, step: Int) -> Date {
        let current = now()
        guard var date = at(time, on: anchor ?? current) else { return current }
        let stepDays = anchor == nil ? 1 : step
        while date <= current {
            guard let next = calendar.date(byAdding: .day, value: stepDays, to: date) else { break }
            date = next
        }
        return date
    }

    /// Та сама дата з годинами й хвилинами `time`.
    private func at(_ time: ReminderTime, on day: Date) -> Date? {
        calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
    }

    private func request(id: String, components: DateComponents, repeats: Bool) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Saifu"
        content.body = "Пора звірити гаманець"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}

#if DEBUG
/// Для #Preview: нічого не планує, дозвіл завжди є.
struct PreviewReminderScheduler: ReminderScheduling {
    func requestAuthorization() async -> Bool { true }
    func schedule(every interval: ReminderInterval, at time: ReminderTime) async {}
    func cancel() {}
}
#endif
