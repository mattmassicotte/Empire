# ``Empire``

Empire is a compile-time defined persistance system backed by a sorted key-value store.

## Overview

Empire is pretty different from many other local persistance systems. It uses your Swift sources define the storage schema and its query capabilities are limited to sorted keys. These two properties have a dramatic effect on how you model and query for your data.

These constraints come from the underlying data storage system, [LMDB](https://www.symas.com/mdb), which uses an ordered-map interface that is very similar to many NoSQL-style databases.

In exchange for these trade-offs, you get a low-overhead system that has strong type-safety guarantees.

## Topics

- ``<doc:DataModelling>``
- ``<doc:Migrations>``
