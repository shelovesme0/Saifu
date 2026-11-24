import CryptoKit
import Foundation

/// Резервна копія всіх гаманців. ViewModel знає лише цей протокол, а не формат файлу.
protocol BackupService {
    /// Файл копії з усіма гаманцями (витрати, поповнення, звірка, порядок).
    func exportData() throws -> Data
    /// Відбиток поточних даних: не змінюється, поки не змінилися гаманці (без дати створення файлу).
    func fingerprint() throws -> String
    /// Читає й перевіряє файл. Поточні дані не змінює. Кидає `BackupError`.
    func validate(_ data: Data) throws -> [CashWallet]
    /// Замінює всі дані гаманцями з перевіреного файлу. Кидає `RepositoryError`, якщо запис не вдався.
    func restore(_ wallets: [CashWallet]) throws
}

/// Дати у файлі — ISO 8601 з мілісекундами: "2026-11-24T03:36:15.654Z".
/// Дата округлюється до цілої мілісекунди і при записі, і при читанні, тому повторний експорт
/// відновлених даних дає той самий рядок (стандартний формат відкидає частку й зсуває дату на 1 мс).
enum BackupDate {
    static func string(from date: Date) -> String {
        let milliseconds = (date.timeIntervalSince1970 * 1000).rounded()
        let seconds = (milliseconds / 1000).rounded(.down)
        let base = Date(timeIntervalSince1970: seconds).formatted(.iso8601) // "…T03:36:15Z"
        return String(base.dropLast()) + String(format: ".%03dZ", Int(milliseconds - seconds * 1000))
    }

    /// Приймає й дати без мілісекунд (наприклад, файл редагували вручну).
    static func date(from text: String) -> Date? {
        let parsed = (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text))
            ?? (try? Date.ISO8601FormatStyle().parse(text))
        return parsed.map { Date(timeIntervalSince1970: ($0.timeIntervalSince1970 * 1000).rounded() / 1000) }
    }
}

/// Копія у форматі JSON (`BackupFileDTO`).
final class JSONBackupService: BackupService {
    private let repository: WalletRepository
    private let appVersion: String

    init(repository: WalletRepository, appVersion: String) {
        self.repository = repository
        self.appVersion = appVersion
    }

    func exportData() throws -> Data {
        let file = BackupFileDTO(formatVersion: BackupFileDTO.currentVersion,
                                 createdAt: Date(),
                                 appVersion: appVersion,
                                 wallets: walletDTOs())
        do {
            return try Self.makeEncoder().encode(file)
        } catch {
            throw BackupError.writeFailed
        }
    }

    func fingerprint() throws -> String {
        // sortedKeys дає однаковий JSON для однакових даних
        let data = try Self.makeEncoder().encode(walletDTOs())
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func validate(_ data: Data) throws -> [CashWallet] {
        let decoder = Self.makeDecoder()
        // Спершу лише версія: файл іншої версії може мати зовсім іншу структуру
        guard let version = try? decoder.decode(BackupVersionDTO.self, from: data) else {
            throw BackupError.corrupted
        }
        guard version.formatVersion == BackupFileDTO.currentVersion else {
            throw BackupError.unsupportedVersion(version.formatVersion)
        }
        guard let file = try? decoder.decode(BackupFileDTO.self, from: data) else {
            throw BackupError.corrupted
        }

        let wallets = try file.wallets.map { try $0.toDomain() }
        // id мають бути унікальними: на них спираються екрани й сховище
        let walletIDs = wallets.map(\.id)
        let entryIDs = wallets.flatMap { $0.expenses.map(\.id) + $0.topUps.map(\.id) }
        guard Set(walletIDs).count == walletIDs.count, Set(entryIDs).count == entryIDs.count else {
            throw BackupError.corrupted
        }
        return wallets
    }

    func restore(_ wallets: [CashWallet]) throws {
        try repository.replaceAll(with: wallets)
    }

    private func walletDTOs() -> [WalletDTO] {
        repository.wallets().map { WalletDTO($0) }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(BackupDate.string(from: date))
        }
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            guard let date = BackupDate.date(from: text) else { throw BackupError.corrupted }
            return date
        }
        return decoder
    }
}
