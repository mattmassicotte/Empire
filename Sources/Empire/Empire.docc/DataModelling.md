# Data Modelling

Understand how to model and query your data.

## Overview

Empire stores records in an ordered-map structure. This has profound implications on query capabilities and how data is modelled. Ordered maps offer much less flexibility than the table-based system of an SQL database. Because of this, data modelling is very influenced by queries you need to support.

## Record Structure

Conceptionally, you can think of each record as being split into two components: the "index key" and "fields".

The "index key" component is the **only** means of retrieving data efficiently. It is **not possible** to run queries against values fields without doing a full scan of the data. This makes index keys a critical part of your design.

Consider the following record defininion. It has a composite key, defined by the two arguments to the `@IndexKeyRecord` macro.

```swift
@IndexKeyRecord("lastName", "firstName")
struct Person {
    let lastName: String
    let firstName: String
    let age: Int
}
```

These records are stored in order, first by `lastName` and then by `firstName`.

`lastName`, `firstName` (Key) | `age` (Fields)                  
--------------------- | ----
`Cornelius`, `Vito` | 58
`Dallas`, `Korben` | 45
`Dallas`, `Mother` | 67
`Rhod`, `Ruby`      | 32
`Zorg`, `Jean-Baptiste Emanuel` | 2000

## Key Ordering

The ordering of key components is very important. Only the last component of a query can be a non-equality comparison. If you want to look for a range of a key component, you must restrict all previous components.

```swift
// scan query on the first component
store.select(lastName: .greaterThan("Dallas"))

// constrain first component, scan query on the second
store.select(lastName: "Dallas", firstName: .lessThanOrEqual("Korben"))

// ERROR: an unsupported key arrangement
store.select(lastName: .lessThan("Zorg"), firstName: .lessThanOrEqual("Jean-Baptiste"))
```

The code generated for a `@IndexKeyRecord` type makes it a compile-time error to write invalid queries.

## Query-First Design

As a consequence of the limited query capability, you must model your data by starting with the queries you need to support. This isn't typically straightforward. One way to go about this is by writing out all of the possible queries your model needs.

Many kinds of query patterns can require denormalization. For example, if we needed to support quering `Person` by age, a **second** entity would be necessary.

```swift
@IndexKeyRecord("age")
struct PersonByAge {
    let age: Int
    let lastName: String
    let firstName: String
}
```

## Type Constraints

The properties of an ``IndexKeyRecord`` type are serialized directly to a binary form. To do this, their types must conform to both the ``Serialization`` and ``Deserialization`` protocols.

However, there is an important additional constraint on types that compose an index key. All of these **must** also be sortable via direct binary comparison when serialized. This is not a property all types have, but can be expressed with a conformance to `IndexKeyComparable`.

| Type | Key | Notes |
| --- | --- | --- |
| `Array`   | no | none |
| `Bool`    | yes | none |
| `Data`    | yes | none |
| `Date`    | no | millisecond precision |
| `Optional`| no | none |
| `Int`     | yes | none |
| `Int64`   | yes | none |
| `RawRepresentable` | no | none |
| `String`  | yes | none |
| `UInt` | yes | none |
| `UInt32` | yes | none |
| `UUID`    | yes | none |

It is possible to add support for custom types using these protocols.

```swift
enum MyEnum: Int, IndexKeyComparable, Serializable, Deserializable {
    case a = 1
    case b = 2
    case c  = 3

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

Preserving the binary ordering sematics required isn't always straightforward. Adding a conformance to `IndexKeyComparable` should be done with care. An inappropriate binary representation will result in undefined querying behavior.
