import Foundation
import Observation

/// Налаштування: гаманці, нагадування про звірку, версія.
@MainActor
@Observable
final class SettingsViewModel {
    /// Ключі UserDefaults для нагадувань (домашню валюту зберігає AppSettings).
    enum Keys {
        static let reminderEnabled = "reminderEnabled"
        static let reminderInterval = "reminderInterval"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
    }

    private let settings: AppSettings
    private let converter: CurrencyConverter
    private let router: AppRouter
    private let scheduler: any ReminderScheduling
    private let defaults: UserDefaults

    let appVersion: String
    private(set) var isReminderEnabled: Bool
    private(set) var reminderInterval: ReminderInterval
    /// Час нагадування; за замовчуванням 20:00.
    private(set) var reminderTime: ReminderTime
    private(set) var reminderMessage: String?

    init(settings: AppSettings,
         converter: CurrencyConverter,
         router: AppRouter,
         scheduler: any ReminderScheduling,
         defaults: UserDefaults,
         appVersion: String) {
        self.settings = settings
        self.converter = converter
        self.router = router
        self.scheduler = scheduler
        self.defaults = defaults
        self.appVersion = appVersion
        #if DEBUG
        rateSourceMode = RateSourceMode.current(in: defaults)
        #endif
        isReminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)
        reminderInterval = ReminderInterval(rawValue: defaults.integer(forKey: Keys.reminderInterval)) ?? .everyThreeDays
        if let hour = defaults.object(forKey: Keys.reminderHour) as? Int,
           let minute = defaults.object(forKey: Keys.reminderMinute) as? Int {
            reminderTime = ReminderTime(hour: hour, minute: minute)
        } else {
            reminderTime = .defaultTime
        }
    }

    // MARK: - Гаманці

    /// Відкриває той самий sheet «Гаманці», що й кнопка на головній.
    func manageWalletsTapped() {
        router.presentWallets()
    }

    // MARK: - Домашня валюта

    /// Зміна одразу оновлює «≈ …» на всіх екранах (AppSettings — @Observable).
    var homeCurrency: Currency {
        get { settings.homeCurrency }
        set { settings.homeCurrency = newValue }
    }

    #if DEBUG
    // MARK: - Розробка (лише Debug)

    /// Джерело курсів: реальне API або режим mock. Зміна одразу перезавантажує курс на всіх екранах.
    var rateSourceMode: RateSourceMode {
        didSet {
            guard rateSourceMode != oldValue else { return }
            defaults.set(rateSourceMode.rawValue, forKey: RateSourceMode.defaultsKey)
            Task { await converter.reload() }
        }
    }
    #endif

    // MARK: - Нагадування

    /// Увімкнення просить дозвіл і планує сповіщення; вимкнення скасовує.
    func setReminderEnabled(_ enabled: Bool) async {
        guard enabled else {
            scheduler.cancel()
            store(enabled: false)
            reminderMessage = nil
            return
        }
        // Тумблер одразу показує «увімкнено», поки система питає дозвіл
        isReminderEnabled = true
        guard await scheduler.requestAuthorization() else {
            store(enabled: false)
            reminderMessage = "Сповіщення вимкнені. Дозвольте їх у Параметрах iOS."
            return
        }
        await scheduler.schedule(every: reminderInterval, at: reminderTime)
        store(enabled: true)
        reminderMessage = nil
    }

    func setReminderInterval(_ interval: ReminderInterval) async {
        reminderInterval = interval
        defaults.set(interval.rawValue, forKey: Keys.reminderInterval)
        await rescheduleIfEnabled()
    }

    /// Час для DatePicker (лише години й хвилини мають значення).
    var reminderTimeDate: Date {
        Calendar.current.date(bySettingHour: reminderTime.hour, minute: reminderTime.minute, second: 0, of: Date()) ?? Date()
    }

    func setReminderTime(_ date: Date) async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let time = ReminderTime(hour: components.hour ?? ReminderTime.defaultTime.hour,
                                minute: components.minute ?? ReminderTime.defaultTime.minute)
        guard time != reminderTime else { return }
        reminderTime = time
        defaults.set(time.hour, forKey: Keys.reminderHour)
        defaults.set(time.minute, forKey: Keys.reminderMinute)
        await rescheduleIfEnabled()
    }

    /// При запуску застосунку: поновлює серію «раз на 3 дні» (та й решту) на найближчі дати.
    func appDidLaunch() async {
        await rescheduleIfEnabled()
    }

    private func rescheduleIfEnabled() async {
        guard isReminderEnabled else { return }
        await scheduler.schedule(every: reminderInterval, at: reminderTime)
    }

    private func store(enabled: Bool) {
        isReminderEnabled = enabled
        defaults.set(enabled, forKey: Keys.reminderEnabled)
    }
}
