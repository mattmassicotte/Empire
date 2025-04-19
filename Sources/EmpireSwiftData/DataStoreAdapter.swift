#if canImport(SwiftData)
import Foundation
import SwiftData

import Empire

enum DataStoreAdapterError: Error {
	case unsupported
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
		var url: URL

		func validate() throws {
		}
	}
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension DataStoreAdapter: DataStore {
	func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, Snapshot> where T : PersistentModel {
		throw DataStoreAdapterError.unsupported
	}
	
	func save(_ request: DataStoreSaveChangesRequest<Snapshot>) throws -> DataStoreSaveChangesResult<Snapshot> {
		for insert in request.inserted {
		}
		
//		Task { [store, identifier] in
//			try await store.withTransaction { ctx in
//				for insert in request.inserted {
//					let entityName = insert.persistentIdentifier.entityName
//					let permanentIdentifier = try PersistentIdentifier.identifier(for: identifier, entityName: entityName, primaryKey: UUID())
//					let snapshotCopy = insert.copy(persistentIdentifier: permanentIdentifier, remappedIdentifiers: nil)
//
//					print(snapshotCopy)
//					let data = try JSONEncoder().encode(snapshotCopy)
//					
//					print(String(decoding: data, as: UTF8.self))
//					print("done")
//				}
//			}
//		}

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
