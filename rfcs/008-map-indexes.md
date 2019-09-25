# Map indexes RFC

---

name: Formal RFC
about: Submit a formal Request For Comments for consideration by the team.
title: ‘Map indexes on FoundationDB’
labels: rfc, discussion
assignees: ''

---

## Introduction

This document describes the data model and index management for building and querying map indexes.

## Abstract

Map indexes will have their data model stored in FoundationDB. Each index is grouped via its design doc's view signature. An index will have the index key/value pairs stored, along with the last sequence number from the changes feed used to update the index.

Indexes will be build using the background jobs api, `couch_jobs`, and will use the changes feed. There will be new size limitations on keys (10KB) and values (100KB) that are emitted from a map function.

## Requirements Language

[note]: # " Do not alter the section below. Follow its instructions. "

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.txt).

## Terminology

`Sequence`: a 13-byte value formed by combining the current `Incarnation` of the database and the `Versionstamp` of the transaction. Sequences are monotonically increasing even when a database is relocated across FoundationDB clusters. See (RFC002)[LINK TBD] for a full explanation.

`View Signature`: A md5 hash of the views, options, view language defined in a design document.

---

## Detailed Description

CouchDB views are used to create secondary indexes in a database. An index is defined by creating map/reduce functions in a design document. This document describes building the map indexes on top of FoundationDB (FDB).

An example map function is shown below:

```json
{
  "_id": "_design/design-doc-id",
  "_rev": "1-8d361a23b4cb8e213f0868ea3d2742c2",
  "views": {
    "map-view": {
      "map": "function (doc) {\n  emit(doc._id, 1);\n}"
    }
  },
  "language": "javascript"
}
```

### Data model

The data model for a map indexed is:

```
(<database>, ?DB_VIEWS, <view_signature>, ?VIEW_UPDATE_SEQ) = Sequence
{<database>, ?DB_VIEWS, <view_signature>, ?VIEW_ID_INFO, view_id, ?VIEW_ROW_COUNT} = <row_count>
{<database>, ?DB_VIEWS, <view_signature>, ?VIEW_ID_INFO, view_id, ?VIEW_KV_SIZE} = <kv_size>
(<database>, ?DB_VIEWS, <view_signature>, ?VIEW_ID_RANGE, <_id>, <view_id>) = [total_keys, total_size, unique_keys]
(<database>, ?DB_VIEWS, <view_signature>, ?VIEW_MAP_RANGE, <view_id>, <key>, <_id>, ?ROW_KEYS <count>) = <emitted_keys>
(<database>, ?DB_VIEWS, <view_signature>, ?VIEW_MAP_RANGE, <view_id>, {<key>, <_id>}, <count>, ?ROW_VALUE) = <emitted_value>
```

Each field is defined as:

- `<database>` is the specific database namespace
- `?DB_VIEWS` is the views namespace.
- `view_signature` is the design documents `View Signature`
- `?VIEW_UPDATE_SEQ` is the change sequence namespace
- `?VIEW_ID_RANGE` is the map id index namespace
- `?VIEW_MAP_RANGE` is the map namespace
- `?ROW_KEYS` is the namespace for a row where the value is the emitted keys from a map function
- `?ROW_VALUE` is the namespace for a row where the value is the emitted value from a map function
- `_id` is the document id
- `view_id` id of a view defined in the design document
- `key` is the encoded emitted row key from a map function
- `count` is a value that is incremented to allow duplicate keys to be emitted for a document
- `emitted_key` is the emitted key from the map function
- `emitted_value` is the emitted value from the map function
- `row_count` number of rows in the index
- `kv_size>` size of the index
- `total_keys` is the number of keys emitted by a document
- `total_size` is the size of the key/values emitted by the document
- `unique_keys` is the unique keys emitted by the document

The `?VIEW_UPDATE_SEQ` row is used to keep track of what sequence in the database changes feed that the index has been indexed up to. It is not possible to update a map index in the same transaction that a document is updated, so the `VIEW_ID_RANGE` namespace is used to keep track of the emitted keys for a document for each map function in a design document. The ?VIEW_MAP_RANGE is the namespace storing the actual emitted keys and values from a map function for a document. For every emitted key/value from a map function, there are two rows in FoundationDB. The first row contains the emitted keys and the second row contains the emitted value from the map function, the `?ROW_KEYS` and `?ROW_VALUE` is added to the key so that emitted keys are always ordered before the value. When the emitted keys are encoded to binary to create the FDB key for a row, strings are converted to sort strings and all numbers are converted to doubles. It is not possible to convert either of those encoded values back to the original value. The `count` value is kept to allow for duplicates. Each emitted key/value pair for a document for a map function is given a `count`. 

The `?VIEW_ROW_COUNT` is used to store the number of rows in the index and `?VIEW_KV_SIZE` keeps track of the size of this index. The size calculation is done using `erlang:external_size`.

The process flow for a document to be indexed is as follows:

1. FDB Transaction is started
1. Read the document from the changes read (The number of documents to read at one type is configurable, the default is 100)
1. The document is passed to the javascript query server and run through all the map functions defined in the design document
1. The view's sequence number is updated to the sequence the document is in the changes feed.
1. The emitted keys are stored in the `?VIEW_ID_RANGE`
1. The emitted keys are encoded then added to the `?VIEW_MAP_RANGE` with the emitted keys and value stored
1. The `?VIEW_ROW_COUNT` is incremented
1. The `?VIEW_KV_SIZE` is increased
1. If the document was deleted and was previously in the view, the previous keys for the document are read from `?VIEW_ID_RANGE` and then cleared from the `?VIEW_MAP_RANGE`. The Row count and size count are also decreased.
1. If the document is being updated and was previously added to the index, then he previous keys for the document are read from `?VIEW_ID_RANGE` and then cleared from the `?VIEW_MAP_RANGE` and then the index is updated with the latest emitted keys and value.

### Key ordering

FoundationDB orders key by byte value which is not how CouchDB orders keys. To maintain CouchDB's view collation, a type value will need to be prepended to each key so that the correct sort order of null < boolean < numbers < strings < arrays < objects is maintained.

In CouchDB 2.x, strings are compared via ICU. The way to do this with FoundationDB is that for every string an ICU sort string will be generated upfront and added to the key.

### Emitting document

In a map function, it is possible to emit the full document as the value, this will cause an issue if the document size is larger than FDB’s value limit of 100 KB. We can handle this in two possible ways. The first is to keep the hard limit of only allowing 100 KB value to be emitted, so if a document exceeds that CouchDB will return an error. This is the preferred option.

The second option is to detect that a map function is emitting the full document and then add in a foreign key reference back to the document subspace. The issue here is that CouchDB would only be able to return the latest version of the document, which would cause consistency issues when combined with the `update=false` argument.

A third option would be to split the document across multiple keys in FoundationDB. This will still be limited by the transaction size limit.

### Index building

An index will be built and updated via a [background job worker](https://github.com/apache/couchdb-documentation/blob/master/rfcs/007-background-jobs.md). When a request for a view is received, the request process will add a job item onto the background queue for the index to be updated. A worker will take the item off the queue and update the index. Once the index has been built, the background job server will notify the request that the index is up to date. The request process will then read from the index and return the results. This process can also be optimised in two ways. Firstly, using a new couch_events system to listen for document changes in a database and then adding indexing jobs to the queue to keep indexes warm. The second optimisation is if the index only requires a small update, rather update the index in the HTTP request process instead of doing the work via the background queue.

Initially, the building of an index will be a single worker running through the changes feed and creating the index. In the future, we plan to parallelise that work so that multiple workers could build the index at the same time. This will reduce build times.

### View clean up

When a design document is changed, new indexes will be built and grouped under a new `View Signature`. The old map indexes will still be in FDB. To clean up will be supported via the existing [/db/_view_cleanup](https://docs.couchdb.org/en/latest/api/database/compact.html#db-view-cleanup) endpoint. 

A future optimisation would be to automate this and have CouchDB to monitor design doc changes and then look to clean up old view indexes via a background worker.

### Stale = “ok” and stable = true

With the consistency guarantee’s CouchDB will get from FDB, `stable = true` will no longer be an option that CouchDB would support and so the argument would be ignored. Similar `stale = “ok”` would now be translated to `update = false`.

### Size limits

- The sum of all keys emitted for a document cannot exceed 100 KB
- Emitted keys will not be able to exceed 10 KB
- Values cannot exceed 100 KB
- There could be rare cases where the number of key-value pairs emitted for a map function could lead to a transaction either exceeding 10 MB in size which isn’t allowed or exceeding 5 MB which impacts the performance of the cluster. In this situation, CouchDB will send an error.

These limits are the hard limits imposed by FoundationDB. We will have to set the user imposed limits to lower than that as we store more information than just the user keys and values.

## Advantages

- Map indexes will work on FoundationDB with the same behaviour as current CouchDB 1.x
- Options like stale = “ok” and ‘stable = true’ will no longer be needed

## Disadvantages

- Size limits on key and values

## Key Changes

- Indexes are stored in FoundationDB
- Indexes will be built via the background job queue
- ICU sort strings will be generated ahead of time for each key that is a string

## Applications and Modules affected

- couch_mrview will be removed and replaced with a new couch_views OTP application

## HTTP API additions

The API will remain the same.

## HTTP API deprecations

- `stable = true` is no longer supported
- `stale = "ok"` is now converted to `update = false`
- reduce functions are not supported in this RFC

## Security Considerations

None have been identified.

## Future improvements

Two future improvements we could look to do that builds upon this work:

- Better error handling for user functions. Currently, if a document fails when run through the map function, a user has to read the logs to discover that. We could look at adding an error-index and a new API endpoint.
- Parallel building of the index. In this RFC, the index is only built sequentially by one index worker. In the future, it would be nice to split that work up and parallelize the building of the index.

## References

- TBD link to background tasks RFC
- [Original mailing list discussion](https://lists.apache.org/thread.html/5cb6e1dbe9d179869576b6b2b67bca8d86b30583bced9924d0bbe122@%3Cdev.couchdb.apache.org%3E)

## Acknowledgements

Thanks to everyone that participated in the mailing list discussion

- @janl
- @kocolosk
- @willholley
- @mikerhodes
