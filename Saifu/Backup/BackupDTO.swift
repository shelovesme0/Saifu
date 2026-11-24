import Foundation

// Формат файлу резервної копії. Окремі DTO, щоб доменні моделі не залежали від формату файлу:
// модель можна змінювати, а старі копії читатимуться через свою версію формату.

/// Весь файл копії. Порядок гаманців — порядок у масиві `wallets`.
struct BackupFileDTO: Codable {
    /// Поточна версія формату. Нова несумісна версія — нове число й окреме читання старих.
    static let currentVersion = 1

    let formatVersion: Int
    let createdAt: Date
    let appVersion: String
    let wallets: [WalletDTO]
}

/// Лише поле версії: читається першим, щоб файл невідомої версії не розбирати далі.
struct BackupVersionDTO: Decodable {
    let formatVersion: Int
}

struct WalletDTO: Codable {
    let id: UUID
    let name: String
    /// `Currency.rawValue`
    let currency: String
    let expenses: [ExpenseDTO]
    let topUps: [TopUpDTO]
    let lastReconciliation: ReconciliationDTO?
}

struct ExpenseDTO: Codable {
    let id: UUID
    let amount: Int
    /// `ExpenseCategory.rawValue`
    let category: String
    let date: Date
    let note: String?
    let receiptID: String?
}

struct TopUpDTO: Codable {
    let id: UUID
    let amount: Int
    let date: Date
    /// `TopUpSource.rawValue`
    let source: String
}

struct ReconciliationDTO: Codable {
    let expected: Int
    let actual: Int
    let date: Date
}

// MARK: - Домен → DTO

extension WalletDTO {
    init(_ wallet: CashWallet) {
        self.init(id: wallet.id,
                  name: wallet.name,
                  currency: wallet.currency.rawValue,
                  // Записи — за датою (і id): SwiftData не зберігає порядок у зв'язках,
                  // а відбиток копії не має змінюватися після перезапуску без змін у даних
                  expenses: wallet.expenses.sorted { Self.chronological($0, $1) }.map { ExpenseDTO($0) },
                  topUps: wallet.topUps.sorted { Self.chronological($0, $1) }.map { TopUpDTO($0) },
                  lastReconciliation: wallet.lastReconciliation.map { ReconciliationDTO($0) })
    }

    /// Порівнюємо дати з тією ж точністю, що й у файлі (мілісекунди), інакше порядок після відновлення зміниться.
    private static func chronological(_ lhs: some WalletEntry, _ rhs: some WalletEntry) -> Bool {
        let left = BackupDate.string(from: lhs.date)
        let right = BackupDate.string(from: rhs.date)
        return left != right ? left < right : lhs.id.uuidString < rhs.id.uuidString
    }
}

extension ExpenseDTO {
    init(_ expense: Expense) {
        self.init(id: expense.id,
                  amount: expense.amount,
                  category: expense.category.rawValue,
                  date: expense.date,
                  note: expense.note,
                  receiptID: expense.receiptID)
    }
}

extension TopUpDTO {
    init(_ topUp: CashTopUp) {
        self.init(id: topUp.id, amount: topUp.amount, date: topUp.date, source: topUp.source.rawValue)
    }
}

extension ReconciliationDTO {
    init(_ reconciliation: Reconciliation) {
        self.init(expected: reconciliation.expected, actual: reconciliation.actual, date: reconciliation.date)
    }
}

// MARK: - DTO → домен (з перевіркою)

// На відміну від сховища, файл міг змінитися зовні, тому невідомі значення не підміняються, а файл вважається пошкодженим.

extension WalletDTO {
    func toDomain() throws -> CashWallet {
        guard let currency = Currency(rawValue: currency) else { throw BackupError.corrupted }
        return CashWallet(id: id,
                          name: name,
                          currency: currency,
                          expenses: try expenses.map { try $0.toDomain() },
                          topUps: try topUps.map { try $0.toDomain() },
                          lastReconciliation: try lastReconciliation?.toDomain())
    }
}

extension ExpenseDTO {
    func toDomain() throws -> Expense {
        guard amount > 0, let category = ExpenseCategory(rawValue: category) else { throw BackupError.corrupted }
        return Expense(id: id, amount: amount, category: category, date: date, note: note, receiptID: receiptID)
    }
}

extension TopUpDTO {
    func toDomain() throws -> CashTopUp {
        guard amount > 0, let source = TopUpSource(rawValue: source) else { throw BackupError.corrupted }
        return CashTopUp(id: id, amount: amount, date: date, source: source)
    }
}

extension ReconciliationDTO {
    func toDomain() throws -> Reconciliation {
        guard actual >= 0 else { throw BackupError.corrupted }
        return Reconciliation(expected: expected, actual: actual, date: date)
    }
}
