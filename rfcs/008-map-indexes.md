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

Map indexes will have their own data model stored in FoundationDB. The model includes grouping map indexes via their design doc's view signature. Each index will have the index key/value pairs stored, along with the last sequence number from the changes feed used to update the index.

Indexes will use the changes feed and be updated via the background tasks queue. If the index only needs a very small update, the update can happen in the request instead of via the background job queue.

There will be new size limitations on keys (10KB) and values (100KB) that are emitted from a map function.

## Requirements Language

[NOTE]: # ( Do not alter the section below. Follow its instructions. )

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.txt).

## Terminology

`Sequence`: a 13 byte value formed by combining the current `Incarnation` of the database and the `Versionstamp` of the transaction. Sequences are monotonically increasing even when a database is relocated across FoundationDB clusters. See (RFC002)[LINK TBD]  for a full explanation.

`View Signature`:  A md5 hash of the views, options, view language defined in a design document.

---

## Detailed Description

CouchDB views are used to create secondary indexes for the documents stored in a CouchDB database. An index is defined by creating a map/reduce functions in a design document. This document describes building the map indexes on top of FoundationDB (FDB).

### Data model

A map index is created via a design document, an example is shown below:

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

The view’s map function will be used to generate keys and values which will be stored in FDB as the secondary index. Format for storing the key/values is:

```json
{<database>, ?VIEWS, <view_signature>, ?VIEW_KVS, <view_id>, ?MAP, <key>, <count>, <_id>} -> <emitted_value>
```

Where each field is defined as:

* `<database>` is the specific database namespace
* `?VIEWS` is the standard views namespace.
* `view_signature` is the design documents `View Signature`
* `view_id` name of a view defined in the design document
* `?MAP` is the standard map namespace
* `key` is the emitted row key from a map function
* `count` is a value to allow duplicate keys to be emitted for a document
* `values` is the emitted value from the map function

### Key ordering

FoundationDB orders key by byte value which is not how CouchDB currently orders keys. To maintain the way CouchDB currently does view collation, a type value will need to be prepended to each key so that the correct sort order of null < boolean < numbers < strings < arrays < objects is maintained.

Strings will need an additional change in terms of how they are compared with ICU. An ICU sort string will be generated upfront and added to the string key. This value will be used to sort the string in FDB. The original string will be stored so that it can be used when returning the keys to the user.

CouchDB allows duplicate keys to be emitted for an index, to allow for that a counter value `count` will be added to the end of the keys.

### Emitting document

In a map function it is possible to emit the full document as the value, this will cause an issue if the document size is larger than FDB’s value limit of 100 KB. We can handle this in two possible ways.  The first is to keep the hard limit of only allowing 100 KB value to be emitted, so if a document exceeds that CouchDB will return an error. This is the preferred option.

The second option is to detect that a map function is emitting the full document and then add in a foreign key reference back to the document subspace. The issue here is that CouchDB would only be able to return the latest version of the document, which would cause consistency issues when combined with the `update=false` argument.

A third option would be to split the document across multiple keys in FoundationDB. This will still be limited by the transaction size limit.

### Index Management

For every document that needs to be processed for an index, we have to run the document through the javascript query server to get the emitted keys and values. This means that it won’t be possible to update a map/reduce index in the same transaction that a document is updated. To account for this, we will need to keep an `id index` similar to the `id tree`  that is currently keep in CouchDB. This index will hold the document id as the key and the value would be the keys that were emitted. CouchDB will use this information to know which fields need to be updated, added or removed from the index when a document is changed.  A data model for this would be:

`{<database>, ?VIEWS, <view_signature>, ?VIEW_ID_INDEX, <_id>, <view_id>} -> [emitted keys]`

Each index will be built and updated via the Background job queue [RFC Link TBD]. When a request for a view is received, the request process will add a job item onto the background queue for the index to be updated. A worker will take the item off the queue and update the index. Once the index has been built, the request will return with the results. This process can also be optimised in two ways. Firstly, using a new couch_events system to listen for document changes in an database and then adding indexing jobs to the queue to keep indexes warm. The second optimisation is if the index only requires a small update, rather update the index in the http request process instead of doing the work via the background queue.

Initially the building of an index will be a single worker running through the changes feed and creating the index. Ideally it would be nice to parallelise that work so that multiple workers could build the index at the same time. This will reduce build times. This can be done by fetching the boundary keys for the changes feed, splitting those key ranges amongst different workers to build different parts of the index. This will require that for each document update processed, the worker must check the revision key space to determine if the document is the latest revision of the document. If it is not it should discard it. The other requirement is that CouchDB could only start serving the index once the update sequence is up to date AND all the workers have completed building their section of the index.

### View clean up

When a design document is changed, new indexes will be built and grouped under a new `View Signature`. The old map indexes will still be in FDB.  CouchDB will need to monitor `View Signatures` and be able to remove old indexes. To do this we create the following data model:

`(<database>, ?VIEW_DDOC_IDS, <design_doc_id>) = ViewSignature`
`(<database>, ?VIEW_SIGS, <view_signature>) = Counter`

When a design document is created, CouchDB will store the design document id and the view signature and set the view signature counter to one. On update or deletion of a design document, CouchDB will get the old signature and decrement the counter. 
If the counter is 0, then CouchDB will remove the old view index.

### Stale = “ok” and stable = true

 With the consistency guarantee’s CouchDB will get from FDB, `stable = true` will no longer be an option that CouchDB would support and so the argument would be ignored. Similar `stale = “ok”` would now be translated to `update = false`.

### Size limits

* The sum of all keys emitted for do a document cannot exceed 100 KB
* Emitted keys will not be able to exceed 10 KB
* Values cannot exceed 100 KB
* There could be rare cases where the number of key-value pairs emitted for a map function could lead to a transaction either exceeding 10 MB in size which isn’t allowed or exceeding 5 MB which impacts the performance of the cluster. Ideally CouchDB will need to detect these situations and split the transaction into smaller transactions

These limits are the hard limits imposed by FoundationDB. We will have to set the user imposed limits to lower than that as we store more information than just the user keys and values.

## Advantages

* Map indexes will work on FoundationDB with same behaviour as current CouchDB 1.x
* Options like stale = “ok” and ‘stable = true’ will no longer be needed

## Disadvantages

* Size limits on key and values
* This RFC does not include a design for reduce functions. That will be done later.

## Key Changes

* Indexes are stored in FoundationDB
* Indexes will be built via the background job queue
* ICU sort strings will be generated ahead of time for each key that is a string

## Applications and Modules affected

* couch_mrview will be removed and replaced with a new indexing OTP application

## HTTP API additions

The API will remain the same.

## HTTP API deprecations

* `stable = true` is no longer supported
* `stale = "ok"` is now converted to `update = false`
* reduce functions are not supported in this RFC

## Security Considerations

None have been identified.

## Future improvements

Two future improvements we could look to do that builds upon this work:

* Better error handling for user functions. Currently if a document fails when run through the map function, a user has to read the logs to discover that. We could look at adding an error index and a new api endpoint.
* Parallel building of the index. In this RFC, the index is only built sequentially by one index worker. In the future it would be nice to split that work up and parallelize the building of the index.

## References

* TBD link to background tasks RFC
* [Original mailing list discussion](https://lists.apache.org/thread.html/5cb6e1dbe9d179869576b6b2b67bca8d86b30583bced9924d0bbe122@%3Cdev.couchdb.apache.org%3E)

## Acknowledgements

Thanks to everyone that participated on the mailing list discussion

* @janl
* @kocolosk
* @willholley
* @mikerhodes
