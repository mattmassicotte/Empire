# Data Manipulation

Learn how to read and write data to a store.

## Overview

There are a variety of APIs available to read and write data to a ``Store``. All operations must be done within a transaction and most are defined in terms of a ``TransactionContext``. However, there are some convenience APIs available to work with a ``Store`` directly.

### Writing

It's important to keep in mind that Empire is fundamentally a key-value store. Because of this, there really isn't a distinction between an "insert" and "update" operation.

Inserting into a context:

```swift
try store.withTransaction { context in
    try context.insert(Person(name: "Korben", age: 45))
}
```

Inserting using a record:

```swift
try store.withTransaction { context in
    try Person(name: "Korben", age: 45).insert(in: context)
}
```

Single-record insert directly into a store instance:

```swift
try Person(name: "Korben", age: 45).insert(in: store)
```

### Reading

### Deleting

Deleting from a context:

```swift
try store.withTransaction { context in
	try context.delete(Person(name: "Korben", age: 45))
}
```

Deleting using a record:

```swift
try store.withTransaction { context in
	try Person(name: "Korben", age: 45).delete(in: context)
}
```

Deleting using a record key:

```swift
try store.withTransaction { context in
	try Person.delete(in: context, key: Person.IndexKey("Korben", 45))
}
```

Single-record delete directly from a store instance:

```swift
try store.delete(Person(name: "Korben", age: 45))
```
