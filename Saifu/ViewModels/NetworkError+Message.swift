import Foundation

/// Тексти мережевих помилок для UI. Окремо від мережевого шару, щоб він не знав про презентацію.
extension NetworkError {
    var userMessage: String {
        switch self {
        case .transport(let error):
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "Немає з'єднання з інтернетом. Перевірте мережу й повторіть."
            case .timedOut:
                return "Сервер НБУ не відповідає. Спробуйте трохи пізніше."
            default:
                return "Не вдалося з'єднатися з сервером НБУ."
            }
        case .badStatus(let code):
            return "Сервер НБУ повернув помилку (код \(code)). Спробуйте пізніше."
        case .decoding:
            return "Сервер НБУ повернув дані в неочікуваному форматі."
        case .empty:
            return LoadState.emptyRatesMessage
        }
    }
}

extension LoadState {
    static let emptyRatesMessage = "НБУ ще не опублікував курс на сьогодні."

    /// Стан після помилки завантаження курсів.
    static func from(_ error: any Error) -> LoadState {
        guard let networkError = error as? NetworkError else {
            return .failed("Не вдалося отримати курс валют.")
        }
        if case .empty = networkError {
            return .empty
        }
        return .failed(networkError.userMessage)
    }
}
