#if canImport(SwiftData)
import SwiftData

enum DataStoreAdapterError: Error {
	case unsupported
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class DataStoreAdapter {
	private let store: Store

	public init(store: Store) {
		self.store = store
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter {
	struct Snapshot: DataStoreSnapshot {
		let persistentIdentifier: PersistentIdentifier

		init(from: any BackingData, relatedBackingDatas: inout [PersistentIdentifier : any BackingData]) {
			self.persistentIdentifier = from.persistentModelID!
		}

		func copy(persistentIdentifier: PersistentIdentifier, remappedIdentifiers: [PersistentIdentifier : PersistentIdentifier]?) -> Self {
			self
		}
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter {
	struct Configuration: DataStoreConfiguration {
		typealias Store = DataStoreAdapter

		var name: String
		var schema: Schema?

		func validate() throws {
			throw DataStoreAdapterError.unsupported
		}
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter: DataStore {
	func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot> where T : PersistentModel {
		throw DataStoreAdapterError.unsupported
	}
	
	func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
		throw DataStoreAdapterError.unsupported
	}

	var identifier: String {
		"hello"
	}
	
	var schema: Schema {
		Schema(Schema.Entity("entity"), version: Schema.Version(1, 2, 3))
	}
	
	var configuration: Configuration {
		Configuration(name: "hello", schema: schema)
	}
	
	convenience init(_ configuration: Configuration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
		throw DataStoreAdapterError.unsupported
	}
}

#endif
