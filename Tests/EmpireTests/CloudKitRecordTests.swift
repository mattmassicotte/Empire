import CloudKit
import Testing

import Empire

@CloudKitRecord
struct CloudKitTestRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

@CloudKitRecord
@IndexKeyRecord("a", "b")
struct IndexKeyCloudKitRecord: Hashable {
	let a: String
	let b: Int
	var c: String
}

struct CloudKitRecordTests {
	@Test func encode() async throws {
		let zone = CKRecordZone.ID(zoneName: "zone", ownerName: "owner")
		let recordId = CKRecord.ID(recordName: "ABC", zoneID: zone)

		let record = CloudKitTestRecord(a: "foo", b: 1, c: "bar")
		let ckRecord = record.ckRecord(with: recordId)

		#expect(ckRecord.recordType == "CloudKitTestRecord")
		#expect(ckRecord["a"] == record.a)
		#expect(ckRecord["b"] == record.b)
		#expect(ckRecord["c"] == record.c)

		let decodedRecord = try CloudKitTestRecord(ckRecord: ckRecord)

		#expect(decodedRecord == record)
	}

	@Test func encodeIndexKeyRecord() async throws {
		let zone = CKRecordZone.ID(zoneName: "zone", ownerName: "owner")

		let record = IndexKeyCloudKitRecord(a: "foo", b: 1, c: "bar")
		let ckRecord = record.ckRecord(in: zone)

		#expect(ckRecord.recordType == "IndexKeyCloudKitRecord")
		#expect(ckRecord.recordID.recordName == "foo1")
		#expect(ckRecord["a"] == record.a)
		#expect(ckRecord["b"] == record.b)
		#expect(ckRecord["c"] == record.c)

		let decodedRecord = try IndexKeyCloudKitRecord(ckRecord: ckRecord)

		#expect(decodedRecord == record)
	}
}
