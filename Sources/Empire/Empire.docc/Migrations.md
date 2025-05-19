# Migrations

Manage changes to your data models over time.

## Overview

Types that conform to ``IndexKeyRecord``, either via the macro or manually, **define** the on-disk serialization format. Any changes to these types will invalidate the data within the storage. This is detected using the `fieldsVersion` and `keyPrefix` properties, and 
fixing it requires migrations. These are run incrementally as mismatches are detected on load.

## Migrating Data

Because the database schema is defined by your types, any changes to these types will invalidate the data within the storage. This is detected using the `fieldsVersion` property, and fixing it requires migrations. These are run incrementally as mismatches are detected on load.

The only factors that affect data compatibility are definition order and data type.

To support migration, you must implement a custom initializer.

```swift
extension struct Person {
    init(_ buffer: inout DeserializationBuffer, version: Int) throws {
        // `version` here is the `fieldVersion` of the data actually serialized in storage
        switch version {
        case 1:
            // this version didn't support the `age` field
            self.lastName = try String(buffer: &buffer.keyBuffer)
            self.firstName = try String(buffer: &buffer.keyBuffer)
            self.age = 0 // a reasonable placeholder I guess?
        default:
            throw Self.unsupportedMigrationError(for: version)
        }
    }
}
```

## Migration Strategy

Here's a possible approach to managing migrations for your record types over time in a more structured way.

```swift
// This represents your current schema
@IndexKeyRecord("key")
struct MyRecord {
    let key: Int
    let a: String
    let b: String
    let c: String
}

extension MyRecord {
    // Here, you keep previous versions of your records.
    @IndexKeyRecord("key")
    private struct MyRecord1 {
        let key: Int
        let a: String
    }

    @IndexKeyRecord("key")
    private struct MyRecord2 {
        let key: Int
        let a: String
        let b: String
    }

    // implement the migration initializer
    public init(_ buffer: inout DeserializationBuffer, version: IndexKeyRecordHash) throws {
        // switch over the possible previous field versions and migrate as necessary
        switch version {
        case MyRecord1.fieldsVersion:
            let record1 = try MyRecord1(&buffer)

            self.key = record1.key
            self.a = record1.a
            self.b = ""
            self.c = ""
        case MyRecord2.fieldsVersion:
            let record2 = try MyRecord2(&buffer)

            self.key = record2.key
            self.a = record2.a
            self.b = record2.b
            self.c = ""
        default:
            throw Self.unsupportedMigrationError(for: version)
        }
    }
}
```

## Schema Version Management

Changing your record types can result in catastrophic failure, so you want to be really careful with them. The `IndexKeyRecord` macro supports a number of other features that can help with migration and schema management.

You can manually encode the field hash into your types to get build-time verification that your schema hasn't changed. What you can do here is inspect the macro output, grab the hash, and then supply it as an argument to the macro. If anything is accidentally changed, an error will be generated.

```swift
@IndexKeyRecord(validated: 8366809093122785258, "key")
public struct VerifiedVersion: Sendable {
    let key: Int
}
```

You can also manually manage the key prefix and field version. This can be useful for easier version management, but you are giving up automated checks by doing this. It is **absolutely critical** that you correctly change this value when you make serialization-incompatible changes.

```swift
@IndexKeyRecord(keyPrefix: 1, fieldsVersion: 2, "key")
struct ManuallyVersionedRecord: Sendable {
    let key: Int
    let value: String
}
```

For reference, the hash algorithm used by the automated system is [sdbm](https://www.partow.net/programming/hashfunctions/#SDBMHashFunction).
