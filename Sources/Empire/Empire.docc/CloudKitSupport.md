# CloudKit Support

Integrate your records with CloudKit.

## Overview

Empire includes support to integrate types into CloudKit.

> Important: CloudKit support is experimental.

## Using `CloudKitRecord`

You can add support for CloudKit's `CKRecord` type via the ``CloudKitRecord`` macro. You can also use the associated protocol independently.

```swift
@CloudKitRecord
struct Person {
    let name: String
    let age: Int
}

// Equivalent to this:
extension Person: CloudKitRecord {
    public init(ckRecord: CKRecord) throws {
        try ckRecord.validateRecordType(Self.ckRecordType)

        self.name = try ckRecord.getTypedValue(for: "name")
        self.age = try ckRecord.getTypedValue(for: "age")
    }

    public func ckRecord(with recordId: CKRecord.ID) -> CKRecord {
        let record = CKRecord(recordType: Self.ckRecordType, recordID: recordId)

        record["name"] = name
        record["age"] = age

        return record
    }
}
```

Optionally, you can override `ckRecordType` to customize the name of the CloudKit record used. If your type also uses ``IndexKeyRecord``, you get access to:

```swift
func ckRecord(in zoneId: CKRecordZone.ID)
```
