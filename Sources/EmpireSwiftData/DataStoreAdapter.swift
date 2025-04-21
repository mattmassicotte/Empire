#if canImport(SwiftData)
import Foundation
import SwiftData

import Empire

@IndexKeyRecord("key")
struct KeyValueRecord {
	let key: UUID
	let value: Data
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class DataStoreAdapter {
	let configuration: Configuration
	private let store: Store

	init(_ configuration: Configuration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
		self.configuration = configuration
		self.store = try Store(url: configuration.url)
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter {
	struct Configuration: DataStoreConfiguration {
		typealias Store = DataStoreAdapter

		var name: String
		var schema: Schema?
		var url: URL

		func validate() throws {
		}
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter: DataStore {
	typealias Snapshot = DefaultSnapshot
	
	func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot> where T : PersistentModel {
		throw DataStoreError.unsupportedFeature
	}
	
	func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
		for insert in request.inserted {
			let entityName = insert.persistentIdentifier.entityName
			let _ = schema.entitiesByName[entityName]
		}

		return DataStoreSaveChangesResult(for: identifier)
	}

	var identifier: String {
		"hello"
	}
	
	var schema: Schema {
		configuration.schema!
	}
}

#endif
