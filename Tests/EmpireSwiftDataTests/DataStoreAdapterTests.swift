#if canImport(SwiftData)
import Foundation
import SwiftData
import Testing

@testable import EmpireSwiftData

@Model
final class ExampleModel {
	var name: String

	init(name: String) {
		self.name = name
	}
}

struct ExampleVersionedSchema : VersionedSchema {
	static let models: [any PersistentModel.Type] = [ExampleModel.self]
	static var versionIdentifier: Schema.Version {
		Schema.Version(1, 0, 0)
	}
}

struct ExampleMigrationPlan : SchemaMigrationPlan {
	static let schemas: [VersionedSchema.Type] = [ExampleVersionedSchema.self]
	static var stages: [MigrationStage] {
		[]
	}
}

@Model
final class Item {
	var name: String
	
	init(name: String) {
		self.name = name
	}
}

extension ModelContainer {
	static var shared: ModelContainer {
		try! ModelContainer(
			for: Schema([Item.self]),
			configurations: .init(isStoredInMemoryOnly: true)
		)
	}
}

struct DataStoreAdapterTests {
	@Test
	@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
	func createAdapter() async throws {
		let schema = Schema([Item.self])
		let url = URL(fileURLWithPath: "/tmp/empire_datastore_store", isDirectory: true)
		try? FileManager.default.removeItem(at: url)
		try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)

		let adapterConfiguration = DataStoreAdapter.Configuration(name: "name", schema: schema, url: url)
		
		let container = try ModelContainer(for: schema, configurations: [adapterConfiguration])
		let context = ModelContext(container)
		
		let item = Item(name: "itemA")
		
		context.insert(item)
		
		try context.save()
	}
}

#endif
