# Data Modelling

Understand how to model and query your data.

## Overview

Empire stores records in an ordered-map structure. This has profound implications on query capabilities and how data is modelled.

You might be more familar with SQL-based databases which use a table-based system. These offer much more flexibility for ad-hoc queries and indexing. Because of this, schemas often closely match the underlying domain. With an ordered-map, data modelling is very closely-related to the queries you need to support.

## Record Structure

Conceptionally, you can think of each record as being split into two components: the "index key" and "fields".

The "index key" component is the **only** means of retrieving data efficiently. It is **not possible** to run queries against values fields without doing a full scan of the data. This makes the design of your index keys a critical part of your design.

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
`Rhod`, `Ruby`      | 32
`Zorg`, `Jean-Baptiste Emanuel` | 2000
