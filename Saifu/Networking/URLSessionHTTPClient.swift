import Foundation

/// Реалізація `HTTPClient` на URLSession (async/await). Єдине місце в застосунку, де робляться мережеві запити.
/// Сам запит URLSession виконує поза головним потоком; виклик лише чекає на `await`, тож UI не блокується.
struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = URLSessionHTTPClient.defaultSession, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            throw NetworkError.transport(error)
        }

        // Спершу статус: тіло з помилкою сервера не намагаємося декодувати
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.transport(URLError(.badServerResponse))
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.badStatus(http.statusCode)
        }
        guard !data.isEmpty else {
            throw NetworkError.empty
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }

    /// Сесія без кешу URLSession (кешуємо самі, на день) і з коротким таймаутом,
    /// щоб без інтернету помилка з'являлася за секунди, а не за хвилину.
    static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()
}
