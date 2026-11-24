import Foundation

/// GET-запит із декодуванням JSON. Кидає лише `NetworkError`.
/// Протокол, щоб джерела даних не залежали від URLSession і їх можна було перевірити без мережі.
protocol HTTPClient {
    func get<T: Decodable>(_ url: URL) async throws -> T
}
