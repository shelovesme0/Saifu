#if DEBUG
import Foundation

/// Lише Debug: яке джерело курсів використовується — реальне API або один із режимів mock.
/// Вибирається в налаштуваннях (секція «Розробка») або аргументом запуску `-rateSource <rawValue>`.
enum RateSourceMode: String, CaseIterable {
    case live
    case mockSuccess, mockEmpty, mockTransportError, mockBadStatus, mockDecodingError, mockSlow

    static let defaultsKey = "debugRateSource"

    var title: String {
        switch self {
        case .live: return "Реальне API НБУ"
        case .mockSuccess: return "Mock: успіх"
        case .mockEmpty: return "Mock: порожньо"
        case .mockTransportError: return "Mock: немає мережі"
        case .mockBadStatus: return "Mock: помилка сервера (503)"
        case .mockDecodingError: return "Mock: неправильний формат"
        case .mockSlow: return "Mock: повільно (3 с)"
        }
    }

    var mockMode: MockRecordSource.Mode? {
        switch self {
        case .live: return nil
        case .mockSuccess: return .success
        case .mockEmpty: return .empty
        case .mockTransportError: return .transportError
        case .mockBadStatus: return .badStatus
        case .mockDecodingError: return .decodingError
        case .mockSlow: return .slow
        }
    }

    static func current(in defaults: UserDefaults) -> RateSourceMode {
        defaults.string(forKey: defaultsKey).flatMap(RateSourceMode.init(rawValue:)) ?? .live
    }
}

/// Lише Debug: при кожному виклику бере джерело за поточним режимом з UserDefaults.
struct SwitchableRecordSource: NBURecordSource {
    let live: NBURecordSource
    let defaults: UserDefaults

    func records() async throws -> [NBURecord] {
        guard let mode = RateSourceMode.current(in: defaults).mockMode else {
            return try await live.records()
        }
        return try await MockRecordSource(mode: mode).records()
    }
}
#endif
