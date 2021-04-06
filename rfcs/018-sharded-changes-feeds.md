---
name: Formal RFC
about: Submit a formal Request For Comments for consideration by the team.
title: 'High Throughput Parallel _changes Feed'
labels: rfc, discussion
assignees: ''

---

# Introduction

This proposal is designed to improve indexing throughput, reduce hot spots for
write-intensive workloads, and offer a horizontally-scalable API for consumers
to process the change capture feed for an individual database in CouchDB 4.0.

## Abstract

The current implementation on `main` writes all changes feed entries for a given
database into a single `?DB_CHANGES` subspace in FoundationDB. The view indexing
system (c.f. [RFC 008](008-map-indexes.md#index-building)) uses a single worker
for each design document that processes all the entries for that changes feed.
High throughput writers can overwhelm that indexer and ensure that it will never
bring the view up-to-date. The previous RFC mentions parallelizing the build as
a future optimization. Well, here we are.

The parallelization technique proposed herein shards the changes feed itself
into multiple subspaces. This reduces the write load on any single underlying
FoundationDB storage server. We also introduce a new external API for accessing
these individual shards directly to ensure that consumers can scale out to keep
up with write-intensive workloads without needing to build their own system to
farm out changes from a single feed to multiple workers.

Shard counts on a database can vary over time as needed, but previous entries
are not re-sharded. We sketch how an indexer can process the individual sharded
feeds in parallel without sacrificing the isolation semantics of the secondary
index (i.e., that it observes the state of the underlying database as it existed
as some specific sequence). Sequence numbers are globally unique and totally
ordered across shards.

## Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.txt).

## Terminology

**changes shard**: a subspace in FoundationDB into which some portion of the
changes feed entries for that database are written. It is not directly related
to the underlying storage server shards in FoundationDB itself.

---

# Detailed Description

## Data Model

The existing `?DB_CHANGES` subspace will be deprecated (i.e. renamed as
`?DB_CHANGES_DEPRECATED`) and a new `?DB_CHANGES` subspace will be created. This
subspace will contain an additional nested level with the individual shard
identifiers. Within each shard the data model is unchanged from before.

## Routing

Documents will be routed to shards using a configurable hashing scheme. The
default scheme will use consistent hashing on the partition key, so that a) all
updates to a given document will land in the same shard, and b) documents from
the same partition in a partitioned database will also be colocated. This
simplifies matters for a consumer processing the individual shard feeds in
parallel, as it can ignore the possibility of observing out-of-order updates to
the same document from different shards, and it furthermore allows the
computation of per-partition statistics (e.g. windowing functions over meter
readings in the canonical IoT device use case for partitions).

## Resharding

The shard count for a database can change over time. When the shard count
changes, a new set of `ShardIds` in the `?DB_CHANGES` subspace is created, and
all future updates to that database will be routed to those new subspaces.
Consumers of the shard-level API will receive a notification that a resharding
event has occurred once they reach the end of the updates committed to the
previous subspace. They MUST re-connect to the new endpoints once they receive
that notification in order to receive any additional updates.

## Metadata

We will extend the `?DB_CONFIG` subspace to add new information about the
changes shards in a new `?CHANGES_SHARDS` nested subspace. This metadata will
include the first sequence at which the new shard topology is active, the ID of
the hashing scheme being used for that shard map, and a list of the associated
`ShardIds`. For example, a newly-created DB will have the following entry
indicating it only has a single shard:

`{?DB_CONFIG, ?CHANGES_SHARDS, 0} = {DefaultHashingScheme, [ShardID]}`

Increasing the shard count to 4 at Sequence 5678 will cause the following entry
to be added:

`{?DB_CONFIG, ?CHANGES_SHARDS, 5678} = {DefaultHashingScheme, [ShardID1, ShardID2, ShardID3, ShardID4]}`

Resharding should also update the previous `?CHANGES_SHARDS` entry with a
flag as a tombstone for this shard map:

`{?DB_CONFIG, ?CHANGES_SHARDS, 0} = {DefaultHashingScheme, [ShardID], Tombstone}`

As mentioned previously, `ShardID` values are always unique and never reused.

### Backwards Compatibility

Existing databases will receive an entry in this subspace formatted like

`{?DB_CONFIG, ?CHANGES_SHARDS, 0} = {?DB_CHANGES_DEPRECATED}`

and then a new one immediately thereafter indicating that new entries will land in a new subspace:

`{?DB_CONFIG, ?CHANGES_SHARDS, CurrentSeq} = {DefaultHashingScheme, [ShardID]}`

## Write Path

Writers that are updating a particular document need to remove the previous
entry for that document. The metadata that we maintain above is sufficient to
calculate a ShardID given a partition key and a sequence, so we do not need to
store the ShardID of the previous update directly in the document metadata.

Once the previous entry is found and removed, the writer publishes the new
update into the appropriate shard given the current shard map.

Writers MUST NOT commit updates to a ShardID that has been replaced as part of a
resharding event. This can be avoided by ensuring that the current
`?CHANGES_SHARDS` entry is included in the read conflict set for the
transaction, so that if a resharding event takes place underneath it the current
write transaction will fail (because of the tombstone commit).

## Read Path

Readers who are connected directly to the shard-level changes feed will retrieve
the shard topology for the database as of the `since` sequence from which they
want to start. This retrieval will need to include the possibility that the
changes exist in the deprecated subspace.

## Indexers

Updating a view group should be thought of a single "job" comprised of a set of
"tasks" that are executed in parallel, one for each shard. Some coordination is
required at the beginning and the end of the job: all tasks within the job
should start from the same snapshot of the underlying database, and when they
complete they should also have observed the same snapshot of the underlying
database. If tasks need to acquire new snapshots along the way because of the
large number of updates they need to process they can do so without
coordination, but in the end the parent job MUST ensure that all tasks have
updated to the same final snapshot.

## Backwards Compatibility

The existing `_changes` endpoint will continue to function. We will implement
a scatter/gather coordinator following the same logic that we used for views in
"classic" CouchDB. Note that sequence entries are totally-ordered and unique
across all shards, so we can reassemble a single ordered list of updates as if
we were dealing with a single subspace the entire time.

# Advantages and Disadvantages

Advantages
- Reduced write hotspots in FoundationDB
- Linearly scalable indexing throughput
- Linearly scalable _changes feed consumption

Disadvantages
- Introduction of a new per-database tunable parameter
- No retroactive improvement in _changes throughput for the sequence range prior
  to the reshard event (e.g., a new index added to the database will start with
  the parallelism defined at DB creation time)
 
# Key Changes

Users would be able to modify the shard count of the changes feed up and down to
have some control over resources devoted to background index maintenance. While
backwards compatbility with the existing `_changes` API would be maintained, a
new API would directly expose the shard-level feeds for easier, more efficient
parallel consumption.

## Applications and Modules affected

`fabric2_fdb:write_doc/6` currently contains the logic that chooses where to
write the sequence index entries.

`fabric2_db:fold_changes/5` is the code that currently consumes the changes from
the `?DB_CHANGES` subspace. We might repurpose this to be the code that reads
from a single shard. The `fold_changes/5` code is only used in two locations:

- `chttpd_changes:send_changes/3`, i.e. the external API
- `couch_views_indexer:fold_changes/2`, i.e. the indexing subsystem

Additionally, we have `fabric2_fdb:get_last_change/1` that would need to be
modified to take the highest sequence across all current shards of the database.

We would likely have a new `fabric2_changes` module to collect the logic for
discovering endpoints, scatter/gather merging of shard feeds, resharding
invocations, etc.

## HTTP API additions

Happy to take suggestions on what color to paint the shed, but I imagine
something like

`GET /db/_changes/<ShardID>`

will provide the change feed for a given shard using all the same semantics as
the current changes endpoint, while

`GET /db/_changes/_meta?since=N`

can be used to retrieve the shard topology as of a particular sequence.

## HTTP API deprecations

None, although the shard-level endpoint above would be recommended over the
regular `/db/_changes` endpoint for users who have write-intensive workloads
and/or are conscious of the CPU overhead on the CouchDB server.

# Security Considerations

None.

# References

[dev@couchdb thread](https://lists.apache.org/thread.html/r3a9ec3bee94ebb2c3296b4b429b42ab04b9b44f6de49338ebd4dc660%40%3Cdev.couchdb.apache.org%3E)

# Acknowledgements

@glynnbird

