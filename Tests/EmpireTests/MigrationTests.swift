import Foundation
import Testing

import Empire

@IndexKeyRecord(keyPrefix: 642254044, fieldsVersion: 10, "key")
struct MismatchedKeyOnlyRecord: Hashable {
	let key: UInt
	let value: String
}

@IndexKeyRecord(keyPrefix: 642254044, fieldsVersion: 20, "key")
struct MigratableKeyOnlyRecord: Hashable {
	let key: UInt
	let value: String
	
	static let valuePlaceholder = "<placeholder>"
}

extension MigratableKeyOnlyRecord {
	// this is the code that actually checks for and peforms the migration
	public static func deserialize(with deserializer: consuming RecordDeserializer, version: IndexKeyRecordHash) throws -> sending MigratableKeyOnlyRecord {
		switch version {
		case KeyOnlyRecord.fieldsVersion:
			let record = try KeyOnlyRecord.deserialize(with: deserializer)

			return MigratableKeyOnlyRecord(
				key: record.key,
				value: Self.valuePlaceholder
			)
		default:
			throw Self.unsupportedMigrationError(for: version)
		}
	}
}

@Suite(.serialized)
struct MigrationTests {
	static let storeURL = URL(fileURLWithPath: "/tmp/migration_tests_store", isDirectory: true)
	
	init() throws {
		try? FileManager.default.removeItem(at: Self.storeURL)
		try FileManager.default.createDirectory(at: Self.storeURL, withIntermediateDirectories: false)
	}
	
	@Test func mismatchedFieldsVersion() throws {
		#expect(MismatchedKeyOnlyRecord.keyPrefix == KeyOnlyRecord.keyPrefix)
		
		let mismatchedRecord = MismatchedKeyOnlyRecord(key: 5, value: "hello")

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(mismatchedRecord)
		}

		let output: MismatchedKeyOnlyRecord? = try store.withTransaction { ctx in
			try ctx.select(key: MismatchedKeyOnlyRecord.IndexKey(5))
		}

		#expect(mismatchedRecord == output)

		#expect(
			throws: StoreError.migrationUnsupported("KeyOnlyRecord", KeyOnlyRecord.fieldsVersion, MismatchedKeyOnlyRecord.fieldsVersion)
		) {
			let _ = try store.withTransaction { ctx in
				try KeyOnlyRecord.select(in: ctx, key: .equals(5))
			}
		}
	}
	
	@Test func migratableFieldsVersion() throws {
		#expect(MigratableKeyOnlyRecord.keyPrefix == KeyOnlyRecord.keyPrefix)
		
		let record = KeyOnlyRecord(key: 5)

		let store = try Store(url: Self.storeURL)

		try store.withTransaction { ctx in
			try ctx.insert(record)
		}

		let output: MigratableKeyOnlyRecord? = try store.withTransaction { ctx in
			try ctx.select(key: MigratableKeyOnlyRecord.IndexKey(5))
		}

		#expect(output?.key == 5)
		#expect(output?.value == MigratableKeyOnlyRecord.valuePlaceholder)
	}
}
