<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Matrix][matrix badge]][matrix]

</div>

# Empire

A record store for Swift

- Schema is defined by your types
- Macro-based API that is both typesafe and low-overhead
- Built for Swift 6
- Support for CloudKit's `CKRecord`
- Backed by a sorted-key index data store ([LMDB][LMDB])

> [!WARNING]
> This library is still pretty new and doesn't have great deal of real-world testing yet.

```swift
import Empire

@IndexKeyRecord("name")
struct Person {
    let name: String
    let age: Int
}

let store = try Store(path: "/path/to/store")

try await store.withTransaction { context in
    try context.insert(Person(name: "Korben", age: 45))
    try context.insert(Person(name: "Leeloo", age: 2000))
}

let records = try await store.withTransaction { context in
    try Person.select(in: context, limit: 1, name: .lessThan("Zorg"))
}

print(record.first!) // Person(name: "Leeloo", age: 2000)
```
 
## Integration

```swift
dependencies: [
    .package(url: "https://github.com/mattmassicotte/Empire", branch: "main")
]
```

## Building

**Note**: requires Xcode 16

- clone the repo
- `git submodule update --init --recursive`

## Data Modeling and Queries

Empire uses a data model that is **extremely** different from a traditional SQL-backed data store. It is pretty unforgiving and can be a challenge, even if you are familiar with it.

Conceptually, you can think of every record as being split into two tuples: the "index key" and "fields".

### Keys

The index key is a critical component of your record. Queries are **only** possible on components of the index key.

```swift
@IndexKeyRecord("lastName", "firstName")
struct Person {
    let lastName: String
    let firstName: String
    let age: Int
}
```

The arguments to the `@IndexKeyRecord` macro define the properties that make up the index key. The `Person` records are sorted first by `lastName`, and then by `firstName`. The ordering of key components is very important. Only the last component of a query can be a non-equality comparison. If you want to look for a range of a key component, you must restrict all previous components.

```swift
// scan query on the first component
store.select(lastName: .greaterThan("Dallas"))

// constrain first component, scan query on the second
store.select(lastName: "Dallas", firstName: .lessThanOrEqual("Korben"))

// ERROR: an unsupported key arrangement
store.select(lastName: .lessThan("Zorg"), firstName: .lessThanOrEqual("Jean-Baptiste"))
```

The code generated for a `@IndexKeyRecord` type makes it a compile-time error to write invalid queries.

As a consequence of the limited query capability, you must model your data by starting with the queries you need to support. This can require denormalization, which may or may not be appropriate for your expected number of records.

### Format

Your types **are** the schema. The type's data is serialized directly to a binary form using code generated by the macro. Making changes to your types will make deserialization of unmigrated data fail. All types that are stored in a record must conform to both the `Serialization` and `Deserialization` protocols. However, all index key members **must** also be sortable via direct binary comparison when serialized. This is not a property many types have, but can be expressed with a conformance to `IndexKeyComparable`.

| Type | Limitations |
| --- | --- |
| `String` | none |
| `UInt`   | none |
| `Int`    | `(Int.min + 1)...(Int.max)` |
| `UUID`   | none |
| `Data`   | none |
| `Date`   | millisecond precision |

### Migrations

Because the database schema is defined by your types, any changes to these types will invalidate the data within the storage. This is detected using the `fieldsVersion` property, and 
fixing it requires migrations. These are run incrementally as mismatches are detected on load.

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
    public init(_ buffer: inout DeserializationBuffer, version: Int) throws {
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

### Schema Version Management

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

## `IndexKeyRecord` Conformance

The `@IndexKeyRecord` macro expands to a conformance to the `IndexKeyRecord` protocol. You can use this directly, but it isn't easy. You have to handle binary serialization and deserialization of all your fields. It's also critical that you version your type's serialization format.

```swift
@IndexKeyRecord("name")
struct Person {
    let name: String
    let age: Int
}

// Equivalent to this:
extension Person: IndexKeyRecord {
    public typealias IndexKey = Tuple<String, Int>
    public associatedtype Fields: Tuple<Int>

    public static var keyPrefix: Int {
        1
    }

    public static var fieldsVersion: Int {
        1
    }

    public var fieldsSerializedSize: Int {
        age.serializedSize
    }

    public var indexKey: IndexKey {
        Tuple(name)
    }

    public func serialize(into buffer: inout SerializationBuffer) {
        name.serialize(into: &buffer.keyBuffer)
        age.serialize(into: &buffer.valueBuffer)
    }

    public init(_ buffer: inout DeserializationBuffer) throws {
        self.name = try String(buffer: &buffer.keyBuffer)
        self.age = try UInt(buffer: &buffer.valueBuffer)
    }
}

extension Person {
    public static func select(in context: TransactionContext, limit: Int? = nil, name: ComparisonOperator<String>) throws -> [Self] {
        try context.select(query: Query(last: name, limit: limit))
    }
    public static func select(in context: TransactionContext, limit: Int? = nil, name: String) throws -> [Self] {
        try context.select(query: Query(last: .equals(name), limit: limit))
    }
}
```

## `CloudKitRecord` Conformance

Empire supports CloudKit's `CKRecord` type via the `CloudKitRecord` macro. You can also use the associated protocol independently.

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

Optionally, you can override `ckRecordType` to customize the name of the CloudKit record used. If your type also uses `IndexKeyRecord`, you get access to:

```swift
func ckRecord(in zoneId: CKRecordZone.ID)
```

## Questions

### Why does this exist?

I'm not sure! I haven't used [Core Data](https://developer.apple.com/documentation/coredata) or [SwiftData](https://developer.apple.com/documentation/swiftdata) too much. But I have used the distributed database [Cassandra](https://cassandra.apache.org) quite a lot and [DynamoDB](https://aws.amazon.com/dynamodb/) a bit. Then one day I discovered [LMDB][LMDB]. Its data model is quite similar to Cassandra and I got interested in playing around with it. This just kinda materialized from those experiments.

### Can I use this?

Sure!

### *Should* I use this?

User data is important. This library has a bunch of tests, but it has no real-world testing. I plan on using this myself, but even I haven't gotten to that yet. It should be considered *functional*, but experimental.

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. Both a [Matrix space][matrix] and [Discord][discord] are available for live help, but I have a strong bias towards answering in the form of documentation. You can also find me on [the web](https://www.massicotte.org).

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/mattmassicotte/Empire/actions
[build status badge]: https://github.com/mattmassicotte/Empire/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/mattmassicotte/Empire
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmattmassicotte%2FEmpire%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/mattmassicotte/Empire/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
[LMDB]: https://www.symas.com/lmdb
