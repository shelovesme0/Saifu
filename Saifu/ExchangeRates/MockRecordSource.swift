#if DEBUG
import Foundation

/// Lише Debug: джерело курсів без мережі для показу всіх станів UI, у тому числі негативних.
struct MockRecordSource: NBURecordSource {
    enum Mode: String, CaseIterable {
        case success, empty, transportError, badStatus, decodingError, slow
    }

    let mode: Mode
    /// Імітація затримки мережі; у `slow` — помітно довша, щоб побачити ProgressView.
    var delay: Duration = .milliseconds(400)
    var slowDelay: Duration = .seconds(3)

    func records() async throws -> [NBURecord] {
        try await Task.sleep(for: mode == .slow ? slowDelay : delay)
        switch mode {
        case .success, .slow:
            return Self.sampleRecords
        case .empty:
            // Так само, як реальний NBURemoteRecordSource на відповідь `[]`
            throw NetworkError.empty
        case .transportError:
            throw NetworkError.transport(URLError(.notConnectedToInternet))
        case .badStatus:
            throw NetworkError.badStatus(503)
        case .decodingError:
            let context = DecodingError.Context(codingPath: [], debugDescription: "Тіло відповіді не є JSON")
            throw NetworkError.decoding(DecodingError.dataCorrupted(context))
        }
    }

    /// Курси НБУ на 24.11.2026 (значення з реальних відповідей API).
    static let sampleRecords = [
        NBURecord(r030: 392, txt: "Єна", rate: Decimal(string: "0.28336")!, cc: "JPY", exchangedate: "24.11.2026"),
        NBURecord(r030: 840, txt: "Долар США", rate: Decimal(string: "45.0811")!, cc: "USD", exchangedate: "24.11.2026"),
        NBURecord(r030: 978, txt: "Євро", rate: Decimal(string: "49.455")!, cc: "EUR", exchangedate: "24.11.2026")
    ]
}
#endif
