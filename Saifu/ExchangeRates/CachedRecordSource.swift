import Foundation

/// Скидання кешу курсів (pull-to-refresh, «Повторити», зміна джерела в Debug).
protocol RateCacheInvalidating {
    func invalidate()
}

/// Декоратор над будь-яким `NBURecordSource`: курс на день береться з мережі один раз.
/// `NBURateAdapter` викликає `records()` для кожної валюти, тож одночасні виклики
/// чекають на одне спільне завантаження, а не запускають власні.
final class CachedRecordSource: NBURecordSource, RateCacheInvalidating {
    private let source: NBURecordSource
    private let now: () -> Date
    private var cached: (day: String, records: [NBURecord])?
    private var inFlight: Task<[NBURecord], Error>?
    /// Зростає при `invalidate()`: результат завантаження, розпочатого до скидання, у кеш не потрапляє.
    private var generation = 0

    init(source: NBURecordSource, now: @escaping () -> Date = Date.init) {
        self.source = source
        self.now = now
    }

    func records() async throws -> [NBURecord] {
        let day = Self.dayKey(now())
        if let cached, cached.day == day {
            return cached.records
        }
        if let inFlight {
            return try await inFlight.value
        }

        let task = Task { try await source.records() }
        let started = generation
        inFlight = task
        defer { if generation == started { inFlight = nil } }
        let records = try await task.value
        if generation == started {
            cached = (day, records)
        }
        return records
    }

    func invalidate() {
        cached = nil
        inFlight = nil
        generation += 1
    }

    /// Ключ дня за київським часом, як публікує курси НБУ: "20261124".
    private static func dayKey(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
