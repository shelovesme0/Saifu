import Foundation
import SwiftData

/// План міграцій між версіями схеми. Поки версія одна, етапів немає.
enum SaifuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SaifuSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }

    /// Контейнер сховища: на диску (застосунок) або в пам'яті (перевірки, запасний варіант).
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: Schema(versionedSchema: SaifuSchemaV1.self),
            migrationPlan: SaifuMigrationPlan.self,
            configurations: configuration
        )
    }
}
