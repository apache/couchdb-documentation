---
name: Per-Document Access Control
about: Make the db-per-user pattern obsolete.
title: 'Per-Document Access Control'
labels: rfc, discussion, access control, security
assignees: '@janl'

---

# Introduction

Up until now (version 2.3.1), CouchDB could not serve mutually
untrusting users accessing the same database. If a user has access to
one document in a database, they have access to all other documents in
the database. Some restrictions can be added about writing documents
(designs docs are db-admin only, validate doc update (VDU) functions
could restrict write access based on the writing user and/or the target
document). For the remainder of this document, “db-admin” SHALL include
server admins as well.

## Abstract

This led to CouchDB developers making use of a pattern called
db-per-user, where all documents belonging to one user are kept in a
separate database. This is a decent enough workaround, but has the
following downsides:

- queries across all databases are not possible. An additional
  workaround exists where all per-user databases are replicated
  continuously into a central, admin-only database that can be used for
  querying the entire data set, but that adds latency and uses
  significant CPU resources. Successful systems have been built where
  increased latency could be traded for fewer CPU resources, but
  overall, this is not an optimal design.

- handling many small databases, say >10000 (depending on hardware) can
  become a challenge, if most of them are active concurrently. It
  forces dbs to be set to `q=1`, migrating off `q!=1` requires
  downtime, 10k bidirectional replications are going to need A LOT of
  CPU and RAM. sharing documents among two or more users requires the
  creation of yet more databases.

Per-user document access aims to solve many of the above problems.
Predominantly, that multiple users can use a single database without
being able to see each other’s documents. A first iteration is not
going to solve sharing of documents across multiple users and/or groups.

Goals for this iteration of this feature:

* allow developers to build apps wihtout having to resort to using the
  db-per-user pattern. Specifically PouchDB applications and CouchDB
  setups with a central server/cluster and many independent satellite
  installations with replication should be supported.

Non-goals for now:

* per-access views
* differentiation between read and write access for documents
* sharing individual documents between multiple users or groups.

However, the design of this iteration aims to allow turning these
non-goals into actual goals later.

## Dramatis Personae

*user*: a CouchDB-user, a record defined in the _users db identified by
a username and password, has associated roles.

*developer*: creator of an application built on top of CouchDB

## Requirements Language

[NOTE]: # ( Do not alter the section below. Follow its instructions. )

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this
document are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.txt).

---

# Detailed Description

You will be able to create databases with the “access” feature enabled
via an option passed at database creation time. If you create a
database without that option, it works like any database in CouchDB
today.

This is how you create an access-enabled database:

```
PUT /database?access=true
```

This option can be set only at database creation time, it can’t be
turned off and on while the database exists.

An access-enabled database behaves like this:

* only admin users can read or write to the database (as per 3.x
  defaults)

* admins can grant individual users and groups access to a database
  using the database’s `_security` object. A special new role `_users`
  can be used to say “all users defined in the `_users` database”.

* documents created without an `_access` field are accessible to
  db-admins only

   * this allows existing databases to be replicated into an
     access-enabled database, but granting access of individual docs to
     specific users needs to be an explicit step handled by developers.

* documents created with an `_access` field are only accessible by
  admins and the user named inside `_access`.

   * `_access: ["shirley"]`

      * later iterations of this could allow for `["shirley"]` being
        shorthand for `[{"read": "shirley", "write": "shirley"}]` for
        more fine-grained access control, but that is out of scope for
        this RFC.

   * users can only create documents with their own username in
     `_access`.

   * admins can add any users to `_access`

   * documents can only be owned by one user at any one point.

      * in a 2.0 > X < 4.0 cluster, two different users could create
        the same document with a different _access definition
        concurrently and both get successful write responses back. As
        with _users documents in conflict, if a document has a conflict
        with separate _access entries, it becomes admin-only by
        default. This case needs to be handled by an applications
        _conflict handler.

* document _ids are shared across all users. So only the first user who
  creates the doc `_id: config` gets it. Applications need to ensure to
  work around this and potentially prefix docs with the username before
  writing/replicating them in.

* _security members are allowed to write design docs, but the have to
  have an `_access` field and those design docs with an `_access` field
  are ignored on the server side. Db-admin ddocs get indexes built as
  normal.

   * you can’t access their views, no view indexes are built, their
     validate_doc_update functions do not run on db inserts.

   * this allows full pouchdb / satellite db replication, but avoids
     problems with having 10000s of VDUs or 10000s of view indexes.

* users can not remove themselves from `_access`, nor can they remove
  the `_access` property. They can only `DELETE` a doc.

* If an existing doc changes the user mentioned in `_access` or an admin
  user adds a non-admin user after updating the document a couple of
  times, that new user will gain access to the full history of the
  document.

   * if compaction hasn’t run yet, they get access to all previous
     revision bodies that still exist.

   * all conflicted versions will also be visible to the new user

   * regardless of compaction, they get access to the full list of
     revision ids for the document. Extremely crafty people could try
     to create a matching body for a revision they didn’t have access
     to by trying to recreate an old hash.

* accessing `_changes` gives users the subset of docs they own in last
  updated order

   * gaps in the sequence id would allow folks to deduce how many other
     docs have been created/updated/deleted in between two of their
     docs.

      * this includes all the user’s docs PLUS all non-`_access` design
        docs, so apps can centrally control design docs going down to
        satellites.

* accessing `_all_docs` gives users the subset of docs they own in `_id`
  order.

   * this includes all the user’s docs PLUS all non-`_access` design
     docs, so apps can centrally control design docs going down to
     satellites.

* Replication check-points / local docs

   * local docs behave exactly like regular docs in that they have to
     include an _access property when being written by a non-admin user.

      * this means that replicator implementations will have to be
        amended to include that property in the checkpoint local docs
        they write.

      * that `_access` property then will also have to be included in
        the replication session id calculation to make sure each user
        gets their own replication id

## Implementation Details

The main addition is a new native query server called
`couch_access_native_proc`, which implements two new indexes
`by-access-id` and `by-access-seq` which do what you’d expect, pass in
a userCtx and retrieve the equivalent of `_all_docs` or `_changes`, but
only including those docs that match the username and roles in their
`_access` property. The existing handlers for `_all_docs` and
`_changes` have been augmented to use the new indexes instead of the
default ones, unless the user is an admin.

https://github.com/apache/couchdb/compare/access?expand=1&ws=0#diff-fbb5
3323f07579be5e46ba63cb6701c4


# Advantages and Disadvantages

The downsides of this are the additional bookkeeping required in the
newly created `by-access-seq` and `by-access-id` indexes. Given the
resource requirements of the alternative db-per-user, this is a more
than welcome trade-off.

As a first iteration, this aims to tackle enough probelms to be useful
for solving real-world problems people run into.

I’m envisioning future iterations that add the following features:

* per-access-seq powered views
* differentiation between read and write access for documents
* support for multiple users in `_access: []`
* support for groups in `_access: []`

The latter two might be better suited to be implemented on a future
FoundationDB backend.

All changes proposed here should translate seamlessly to a FoundationDB
future.


# Key Changes

There are no default changes, but folks can op into the new behaviour.

## Applications and Modules affected

`couch`, `couch_mrview`, `couch_index`, `couch_replicator`, `chttpd`

## HTTP API additions

Note: this list is acopypasta from the 2.3.1 API documentation.

`/db`

* no changes

`/db/_all_docs`  
`/db/{doc}`  

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]`

`/db/_design_docs`

* TBD: problem: maybe map admin-only ddocs as `_admin` in `_access`
  index, and then use that for this endpoint. * that would probably
  also help with loading ddocs for VDU evaluation

`/db/_bulk_get`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]`
* ids requested that belong to other users return an `{error: {reason:
  unauthorized}}` row

`/db/_bulk_docs`

* admin: no changes
* user: only the docs where` req.userCtx.name == _access: [$name]`
* ids requested that belong to other users return an `{error: {reason:
  unauthorized}}` row

`/db/_find`  
`/db/_index`  
`/db/_explain`  

* admin only

`/db/_shards` TBD probably no changes

`/db/_shards/doc`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]` plus
 non-_access ddocs

`/db/_sync_shards` TBD probably no changes

`/db/_changes`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]` plus non-_access ddocs

`/db/_compact`  
`/db/_compact/design-doc`  
`/db/_ensure_full_commit`  
`/db/_view_cleanup`  
`/db/_security`  
`/db/_purged_infos_limit`  
`/db/_revs_limit`  

* all no changes

`/db/_purge`

* admin: no changes

* user: only the docs where `req.userCtx.name == _access: [$name]`

`/db/_missing_revs`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]`
* users of _missing_revs (i.e. replicators) need to understand a new
  response format which includes an {error: unauthorized} message.

`/db/_revs_diff`

* admin: no changes
* user: only the docs where req.userCtx.name == _access: [$name]
* users of _missing_revs (i.e. replicators) need to understand a new
  response format which includes an {error: unauthorized} message.

`/db/doc`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]`

`/db/doc/attachment`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]`

`/db/_design/design-doc`  
`/db/_design/design-doc/attachment`  
`/db/_design/design-doc/_info`  

* admin: no changes unless doc includes _access value
* user: no access, see above

`/db/_design/design-doc/_view/view-name`

* admin: no changes
* user: no access, see above

`/db/_design/design-doc/_show/show-name`  
`/db/_design/design-doc/_show/show-name/doc-id`  
`/db/_design/design-doc/_list/list-name/view-name`  
`/db/_design/design-doc/_list/list-name/other-ddoc/view-name`  
`/db/_design/design-doc/_update/update-name`  
`/db/_design/design-doc/_update/update-name/doc-id`  
`/db/_design/design-doc/_rewrite/path`  

* these are available on non-_access ddocs only (or not supported, as
  per other changes)

`/db/_local_docs /db/_local/id`

* admin: no changes
* user: only the docs where `req.userCtx.name == _access: [$name]`
* replication engines MUST be changed to include an _access member in
  the replication definition that can be included in _local checkpoints
  AND _access MUST be included in the session id calculation.

## HTTP API deprecations

None

# Security Considerations

This is a significant change to the CouchDB security model. All of the
above are security considerations.

Specifically these two issues are worth highlighting however:

1. If a doc ever gets a new username written to `_access` (only admins
can do this), that new user then has access to **all** previous
revisions of this document. If compaction hasn’t run yet, they will be
able to access full revision bodies. After compaction, they only get
revision hashes. Since revision hashes are content addressible, they
could try and brute-force a document body that matches an earlier rev
id. This is not a downside of this proposal, it is just something that
implementors have to have in mind.

2. If two users write the same, perviously unexisting document `A` with
differnt values for `_access`, they create a conflict. Since doc
contents may contain sensitive information, CouchDB can’t allow access
to either version. Similar to how conflicting _user docs result in a
user no longer being able to log-in, an admin has to resolve this doc
conflict before the doc can be used again.


# References

https://lists.apache.org/thread.html/6aa77dd8e5974a3a540758c6902ccb509ab5a2e4802ecf4fd724a5e4@%3Cdev.couchdb.apache.org%3E

https://lists.apache.org/thread.html/1aae26aa329817d8c54bab615a0df1c3a7b0fd34f17a2321ecf047f3@%3Cdev.couchdb.apache.org%3E


# Acknowledgements

Thanks to @wohali who helped me talk some of these things through and
of course all of dev@, specifically the Boston Summit attendees for
kickstarting this effort.
