#if canImport(SwiftData)
import SwiftData
import Testing

import Empire

@Model
final class ExampleModel {
	var name: String

	init(name: String) {
		self.name = name
	}
}

struct ExampleVersionedSchema: VersionedSchema {
	static let models: [any PersistentModel.Type] = [ExampleModel.self]
	static var versionIdentifier: Schema.Version {
		Schema.Version(1, 0, 0)
	}
}

struct ExampleMigrationPlan: SchemaMigrationPlan {
	static let schemas: [VersionedSchema.Type] = [ExampleVersionedSchema.self]
	static var stages: [MigrationStage] {
		[]
	}
}

struct DataStoreAdapterTests {
	@Test
	@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
	func createAdapter() async throws {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		let defaultStore = try DefaultStore(config, migrationPlan: ExampleMigrationPlan.self)

		print("store", defaultStore)
	}
}

#endif
