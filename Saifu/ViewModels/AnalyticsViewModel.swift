import Foundation
import Observation

/// Підсумок однієї категорії за період, уже готовий для показу.
struct CategoryStat: Identifiable, Equatable {
    var id: ExpenseCategory { category }
    let category: ExpenseCategory
    let amount: Int
    let amountText: String
    let percentText: String
    let countText: String
}

/// Пункт меню вибору гаманця.
struct WalletOption: Identifiable, Hashable {
    let id: UUID
    /// "Єни · JPY"
    let title: String
}

/// Аналітика: витрати обраного гаманця за категоріями за період.
@MainActor
@Observable
final class AnalyticsViewModel {
    enum Period: CaseIterable, Hashable {
        case week, month, all, custom

        var title: String {
            switch self {
            case .week: return "Тиждень"
            case .month: return "Місяць"
            case .all: return "Усе"
            case .custom: return "Період…"
            }
        }
    }

    private let repository: WalletRepository
    private let converter: CurrencyConverter
    private let settings: AppSettings
    private let router: AppRouter
    private let calendar = Calendar.current

    var selectedWalletID: UUID?
    private(set) var period: Period = .month

    /// Застосований власний діапазон (дні включно).
    private(set) var customStart: Date
    private(set) var customEnd: Date
    /// Чернетка у sheet «Період», поки користувач не натиснув «Застосувати».
    var draftStart: Date
    var draftEnd: Date

    init(repository: WalletRepository,
         converter: CurrencyConverter,
         settings: AppSettings,
         router: AppRouter) {
        self.repository = repository
        self.converter = converter
        self.settings = settings
        self.router = router
        let today = Date()
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        customStart = monthAgo
        customEnd = today
        draftStart = monthAgo
        draftEnd = today
        selectedWalletID = repository.wallets().first?.id
    }

    // MARK: - Гаманець

    private var wallets: [CashWallet] {
        repository.wallets()
    }

    private var selectedWallet: CashWallet? {
        wallets.first { $0.id == selectedWalletID } ?? wallets.first
    }

    /// false, поки не створено жодного гаманця.
    var hasWallets: Bool {
        !wallets.isEmpty
    }

    /// Текст порожнього стану: немає гаманців або немає витрат за період.
    var emptyText: String {
        hasWallets ? "Витрат за період немає" : "Створіть гаманець, щоб бачити аналітику"
    }

    var walletOptions: [WalletOption] {
        wallets.map { WalletOption(id: $0.id, title: "\($0.name) · \($0.currency.code)") }
    }

    var selectedWalletTitle: String {
        guard let wallet = selectedWallet else { return "Гаманець" }
        return "\(wallet.name) · \(wallet.currency.code)"
    }

    /// Гаманець, позначений у меню (з урахуванням видалених).
    var selectedOptionID: UUID? {
        selectedWallet?.id
    }

    func selectWallet(_ id: UUID) {
        selectedWalletID = id
    }

    // MARK: - Період

    /// Вибір чипа: «Період…» відкриває sheet, решта застосовується одразу.
    func selectPeriod(_ newPeriod: Period) {
        if newPeriod == .custom {
            draftStart = customStart
            draftEnd = customEnd
            router.presentAnalyticsPeriod()
        } else {
            period = newPeriod
        }
    }

    /// nil, якщо чернетка коректна.
    var draftError: String? {
        calendar.startOfDay(for: draftStart) > calendar.startOfDay(for: draftEnd)
            ? "Дата «з» має бути не пізніше дати «по»"
            : nil
    }

    func applyCustomPeriod() {
        guard draftError == nil else { return }
        customStart = draftStart
        customEnd = draftEnd
        period = .custom
        router.dismissSheet()
    }

    func cancelCustomPeriod() {
        router.dismissSheet()
    }

    /// Діапазон дат для фільтра; nil — усі витрати.
    private var range: Range<Date>? {
        let now = Date()
        switch period {
        case .week:
            return (calendar.date(byAdding: .day, value: -7, to: now) ?? now)..<Date.distantFuture
        case .month:
            return (calendar.date(byAdding: .day, value: -30, to: now) ?? now)..<Date.distantFuture
        case .all:
            return nil
        case .custom:
            // «по» включно: до початку наступного дня
            let start = calendar.startOfDay(for: customStart)
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEnd)) ?? customEnd
            return start..<max(start, end)
        }
    }

    /// Підпис під сумою в центрі діаграми.
    var periodCaption: String {
        switch period {
        case .week: return "за тиждень"
        case .month: return "за місяць"
        case .all: return "за весь час"
        case .custom:
            let style = Date.FormatStyle.dateTime.day().month(.abbreviated).locale(Locale(identifier: "uk_UA"))
            return "\(customStart.formatted(style)) – \(customEnd.formatted(style))"
        }
    }

    // MARK: - Підсумки

    /// Підсумки за категоріями на основі CashWallet.totalsByCategory, найбільші зверху.
    var stats: [CategoryStat] {
        guard let wallet = selectedWallet else { return [] }
        let range = range
        let totals = wallet.totalsByCategory(in: range)
        let grandTotal = totals.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }

        let periodExpenses = wallet.expenses.filter { range?.contains($0.date) ?? true }
        return totals
            .map { category, amount in
                let count = periodExpenses.filter { $0.category == category }.count
                return CategoryStat(category: category,
                                    amount: amount,
                                    amountText: wallet.currency.format(amount),
                                    percentText: Self.percent(amount, of: grandTotal),
                                    countText: "\(count) шт.")
            }
            // Сталий порядок при однакових сумах — за allCases
            .sorted {
                $0.amount != $1.amount
                    ? $0.amount > $1.amount
                    : Self.order($0.category) < Self.order($1.category)
            }
    }

    private var total: Int {
        stats.reduce(0) { $0 + $1.amount }
    }

    var totalText: String {
        selectedWallet?.currency.format(total) ?? ""
    }

    /// Підпис над «≈ …» — коротко, щоб уміщався поруч із діаграмою на вузьких екранах: "У UAH".
    var convertedCaption: String {
        "У \(settings.homeCurrency.code)"
    }

    /// Стан курсу для блоку «≈ …»; nil, якщо валюта гаманця збігається з домашньою.
    var rateState: LoadState? {
        guard let wallet = selectedWallet, wallet.currency != settings.homeCurrency else { return nil }
        return converter.state
    }

    func retryRatesTapped() {
        Task { await converter.reload() }
    }

    /// "≈ …" у домашній валюті; nil, якщо валюта гаманця збігається з домашньою або курсу ще немає.
    var convertedTotalText: String? {
        guard let wallet = selectedWallet else { return nil }
        return converter.approximateText(total, from: wallet.currency, to: settings.homeCurrency)
    }

    var topCategory: CategoryStat? {
        stats.first
    }

    private static func order(_ category: ExpenseCategory) -> Int {
        ExpenseCategory.allCases.firstIndex(of: category) ?? 0
    }

    private static func percent(_ part: Int, of whole: Int) -> String {
        // Цілочисельне округлення без Double
        "\((part * 100 + whole / 2) / whole)%"
    }
}
