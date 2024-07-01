import CloudKit
import Testing

import Empire

@CloudKitRecord
struct CloudKitTestRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

extension CloudKitTestRecord {
	static var ckRecordType: String {
		String(describing: Self.self)
	}

	func renderCKRecord(in zone: String, owner: String) -> CKRecord {
		let zoneId = CKRecordZone.ID(zoneName: zone, ownerName: owner)

		let recordId = CKRecord.ID(recordName: "abc", zoneID: zoneId)

		return renderCKRecord(with: recordId)
	}

	func renderCKRecord(with recordId: CKRecord.ID) -> CKRecord {
		let record = CKRecord(recordType: Self.ckRecordType, recordID: recordId)

//		namedPrimaryKey.write(to: record)

		return record
	}
}

struct CloudKitRecordTests {
	@Test func encode() async throws {
		let record = CloudKitTestRecord(a: "a", b: 1, c: "c")
		let ckRecord = record.renderCKRecord(in: "zone", owner: "owner")

		#expect(ckRecord.recordType == "AnotherRecord")
		#expect(ckRecord["a"] == "foo")
	}
}
