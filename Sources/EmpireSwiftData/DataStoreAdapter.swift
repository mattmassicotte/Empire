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
final package class DataStoreAdapter {
	package let configuration: Configuration
	private let store: Store

	package init(_ configuration: Configuration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
		self.configuration = configuration
		self.store = try Store(url: configuration.url)
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter {
	package struct Configuration: DataStoreConfiguration {
		package typealias Store = DataStoreAdapter

		package var name: String
		package var schema: Schema?
		package var url: URL
		
		package init(name: String, schema: Schema? = nil, url: URL) {
			self.name = name
			self.schema = schema
			self.url = url
		}

		package func validate() throws {
		}
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter: DataStore {
	package typealias Snapshot = DefaultSnapshot
	
	package func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot> where T: PersistentModel {
		throw DataStoreError.unsupportedFeature
	}
	
	package func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
		for insert in request.inserted {
			let entityName = insert.persistentIdentifier.entityName
			let _ = schema.entitiesByName[entityName]
		}

		return DataStoreSaveChangesResult(for: identifier)
	}

	package var identifier: String {
		"hello"
	}
	
	package var schema: Schema {
		configuration.schema!
	}
}

#endif
