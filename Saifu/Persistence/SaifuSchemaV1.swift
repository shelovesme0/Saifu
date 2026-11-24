import Foundation
import SwiftData

/// Перша версія схеми сховища. Сутності окремі від доменних моделей: домен не знає про SwiftData.
/// Нова версія схеми — новий enum `SaifuSchemaV2` і етап у `SaifuMigrationPlan`.
enum SaifuSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [WalletEntity.self, ExpenseEntity.self, TopUpEntity.self, ReconciliationEntity.self]
    }

    /// Гаманець. Записи й звірка видаляються разом із ним (каскад).
    @Model
    final class WalletEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        /// `Currency.rawValue`
        var currencyRaw: String
        /// Позиція у списку гаманців (0 — перший).
        var sortIndex: Int

        @Relationship(deleteRule: .cascade, inverse: \ExpenseEntity.wallet)
        var expenses: [ExpenseEntity] = []

        @Relationship(deleteRule: .cascade, inverse: \TopUpEntity.wallet)
        var topUps: [TopUpEntity] = []

        @Relationship(deleteRule: .cascade, inverse: \ReconciliationEntity.wallet)
        var lastReconciliation: ReconciliationEntity?

        init(id: UUID, name: String, currencyRaw: String, sortIndex: Int) {
            self.id = id
            self.name = name
            self.currencyRaw = currencyRaw
            self.sortIndex = sortIndex
        }
    }

    @Model
    final class ExpenseEntity {
        var id: UUID
        /// Сума в найменших одиницях валюти гаманця.
        var amount: Int
        /// `ExpenseCategory.rawValue`
        var categoryRaw: String
        var date: Date
        var note: String?
        var receiptID: String?
        var wallet: WalletEntity?

        init(id: UUID, amount: Int, categoryRaw: String, date: Date, note: String?, receiptID: String?) {
            self.id = id
            self.amount = amount
            self.categoryRaw = categoryRaw
            self.date = date
            self.note = note
            self.receiptID = receiptID
        }
    }

    @Model
    final class TopUpEntity {
        var id: UUID
        var amount: Int
        var date: Date
        /// `TopUpSource.rawValue`
        var sourceRaw: String
        var wallet: WalletEntity?

        init(id: UUID, amount: Int, date: Date, sourceRaw: String) {
            self.id = id
            self.amount = amount
            self.date = date
            self.sourceRaw = sourceRaw
        }
    }

    /// Остання звірка гаманця.
    @Model
    final class ReconciliationEntity {
        var expected: Int
        var actual: Int
        var date: Date
        var wallet: WalletEntity?

        init(expected: Int, actual: Int, date: Date) {
            self.expected = expected
            self.actual = actual
            self.date = date
        }
    }
}

// Поточна версія сутностей; з новою схемою псевдоніми вказуватимуть на неї.
typealias WalletEntity = SaifuSchemaV1.WalletEntity
typealias ExpenseEntity = SaifuSchemaV1.ExpenseEntity
typealias TopUpEntity = SaifuSchemaV1.TopUpEntity
typealias ReconciliationEntity = SaifuSchemaV1.ReconciliationEntity
