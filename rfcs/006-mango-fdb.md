# Mango RFC

- - - -
name: Formal RFC
about: Submit a formal Request For Comments for consideration by the team.
title: ‘Mango JSON indexes in FoundationDB’
labels: rfc, discussion
assignees: ‘’

- - - -

[NOTE]: # ( ^^ Provide a general summary of the RFC in the title above. ^^ )

# Introduction

This document describes the data model, querying and indexing management for Mango JSON indexes with FoundationDB.

## Abstract

This document details the data model for storing Mango indexes. Indexes will be updated in the transaction that a document is written to FoundationDB. When an index is created on an existing database, a background task will build the index up to the Sequence that the index was created at.

## Requirements Language

[NOTE]: # ( Do not alter the section below. Follow its instructions. )

The keywords “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”,
“SHOULD”, “SHOULD NOT”, “RECOMMENDED”,  “MAY”, and “OPTIONAL” in this
document are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.txt).

## Terminology

`Sequence`: a 13-byte value formed by combining the current `Incarnation` of the database and the `Versionstamp` of the transaction. Sequences are monotonically increasing even when a database is relocated across FoundationDB clusters. See (RFC002)[LINK TBD] for a full explanation.
- - - -

# Detailed Description

Mango is a declarative JSON querying syntax that allows a user to retrieve documents based on a selector. Indexes can be defined to improve query performance. In CouchDB 2.x Mango is a query layer built on top of Map/Reduce indexes. Each Mango query follows a two-step process, first a subset of the selector is converted into a map query to be used with a predefined index or falling back to `_all_docs` if no indexes are available. Each document retrieved from the index is then matched against the full query selector. 

For CouchDB on FoundationDB, the external behavior of Mango will remain the same but internally it will have its own indexes and index management. This will allow for Mango indexes to be updated in the same transaction where a write request happens - index on write. Later we can also look at adding Mango specific functionality.

## Data Model

### Index Definitions

A Mango index is defined as:

```json
{
  name: ‘view-name’ - optional, will be auto-generated
  index: {
    fields: [‘fieldA’, ‘fieldB’] - fields to be indexed
  },
  partial_filter_selector {} - optional filter to process documents before adding to the index
}
```

The above index definition would be stored in FoundationDB as:

`(?DATABASE, ?INDEX_DEFINITIONS, <fields>) = (<index_name>, <partial_filter_selector>, build_status, sequence, index_version)`
`(?DATABASE, ?INDEX_DEFINITIONS, ?BUILD_INFO) = (sequence, row_count)`

* `index_name` is the name of the index
* `build_status` will have two options:
  * `active` which indicates the index is ready to service queries 
  * `building` if the index is still being built

* `sequence` is the sequence that the index is created at.
* `index_version` will be used to version each index to allow for easier upgrades if we make any changes to the index design later
* `?BUILD_INFO` is the sequence the background build has built the index up to and the number of rows in the index.

### Indexes

Each index defined in the Index Definition would have an index keyspace where the database’s documents are stored and sorted via the keys defined in the index’s definition. The data model for each defined index would be:

`(?DATABASE, ?INDEXES, <index_name>, <indexed_fields>, <_id>) = null`

* `index_name` is the name of the index
* `indexed_fields` are the fields in the document that are indexed from the fields in the index definition
* `_id` is the `_id` of the document that is indexed and used to retrieve the full document for a Mango query.

For now, the value will be null, later we can look at storing covering indexes. aggregate values or materialized views.

### Key sorting

In CouchDB 2.x ICU collation is used to sort string key’s when added to the index’s b-tree. The current way of using ICU string collation won’t work with FoundationDB. To resolve this strings will be converted to an ICU sort string before being stored in FDB. This is an extra performance overhead but will only be done when one when writing a key into the index. 

CouchDB has a defined [index collation specification](http://docs.couchdb.org/en/stable/ddocs/views/collation.html#collation-specification) that the new Mango design must adhere to. Each key added to a Mango index will be converted into a composite key or tuple with the first value in the tuple representing the type that the key so that it would be sorted correctly. The `couch_views_encoding` library will be used to encode all fields correctly.

### Index Limits

This design has certain defined limits for it to work correctly:

* The index definition (`name`, `fields` and `partial_filter_selector`) cannot exceed 100 KB FDB value limit
* The sorted keys for an index cannot exceed the 8 KB key limit
* To be able to update the index in the transaction that a document is updated in, there will have to be a limit on the number of Mango indexes for a database so that the transaction stays within the 10MB transaction limit. This limit is still TBD based on testing.

## Index building and management

When an index is created on an existing database, the index will need to be built for all existing documents in the database. The process for building a new index would be:

1. When a user defines a new index on an existing database, save the index definition along with the `sequence`  the index was added at and set the `build_status` to `building` so it won’t be used to service queries. 
2. Any write requests (document updates) after the saved index definition will update the index with the document update. Index writers should assume that previous versions of the document have already been indexed.
3. At the same time a background process via `couch_jobs` will start reading sections of the changes feed and building the index, this background process will keep processing the changes read until it reaches the sequence number that the index was saved at. Once it reaches that point, the index is up to date and `build_status` will be marked as `active` and the index can be used to service queries.
4. There is some subtle behavior around step 3 that is worth mentioning. The background process will have the 5-second transaction limit, so it will process smaller parts of the changes feed. Which means that it won’t have one consistent view of the changes feed throughout the index building process. This will lead to a conflict situation when the background process transaction is adding a document to the index while at the same time a write request has a transaction that is updating the same document. There are two possible outcomes to this, if the background process wins, the write request will get a conflict. At that point the write request will try to process the document again, read the old values for that document, remove them from the index and add the new values to the index. If the write request wins, and the background process gets a conflict, then the background process can try again, the document would have been removed from its old position in the changes feed and moved to the later position, so the background process won’t see the document and will then move on to the next one. 
5. An index build progress tracker, `?BUILD_INFO` will also be added. This is used to track at what sequence the index has been updated to via the background build process. It will also store the number of rows in the index. This can be used for query planning.

## Advantages

* Indexes are kept up to date when documents are changed, meaning you can read your own writes
* Makes Mango indexes first-class citizens and opens up the opportunity to create more Mango specific functionality

## Disadvantages

* FoundationDB currently does not allow CouchDB to do the document selector matching at the shard level. However, there is a discussion for this [Feature Request: Predicate pushdown](https://forums.foundationdb.org/t/feature-request-predicate-pushdown/954)

## Key Changes

* Mango indexes will be stored separately to Map/Reduce indexes.
* Mango Indexes will be updated when a document is updated
* A background process will build a new Mango index on an existing database
* There are specific index limits mentioned in the Index Limits section.

Index limitations aside, this design preserves all of the existing API options
for working with CouchDB documents.

## Applications and Modules affected

The `mango` application will be modified to work with FoundationDB


## HTTP API additions

None.

## HTTP API deprecations

None,

# Security Considerations

None have been identified.

# References

[Original mailing list discussion](https://lists.apache.org/thread.html/b614d41b72d98c7418aa42e5aa8e3b56f9cf1061761f912cf67b738a@%3Cdev.couchdb.apache.org%3E)

# Acknowledgements

thanks to following in participating in the design discussion

* @kocolosk
* @willholley
* @janl
* @alexmiller-apple
