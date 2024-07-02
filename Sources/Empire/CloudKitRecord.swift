public protocol CloudKitRecordNameRepresentable {
	var ckRecordName: String { get }
}

#if canImport(CloudKit)
import CloudKit

enum CloudKitRecordError: Error {
	case missingField(String)
	case recordTypeMismatch(String, String)
}

extension CKRecord {
	public func getTypedValue<T>(for key: String) throws -> T {
		guard let field = self[key] as? T else {
			throw CloudKitRecordError.missingField(key)
		}

		return field
	}

	public func validateRecordType(_ expectedType: String) throws {
		if recordType != expectedType {
			throw CloudKitRecordError.recordTypeMismatch(recordType, expectedType)
		}
	}
}

public protocol CloudKitRecord {
	static var ckRecordType: String { get }
	
	func ckRecord(with recordId: CKRecord.ID) -> CKRecord

	init(ckRecord: CKRecord) throws
}

extension CloudKitRecord {
	public static var ckRecordType: String {
		String(describing: Self.self)
	}
}

extension CloudKitRecord where Self: IndexKeyRecord, Self.IndexKey: CloudKitRecordNameRepresentable {
	public func ckRecord(in zoneId: CKRecordZone.ID) -> CKRecord {
		let recordName = indexKey.ckRecordName
		let recordId = CKRecord.ID(recordName: recordName, zoneID: zoneId)

		return ckRecord(with: recordId)
	}
}

#endif
