.. Licensed under the Apache License, Version 2.0 (the "License"); you may not
.. use this file except in compliance with the License. You may obtain a copy of
.. the License at
..
..   http://www.apache.org/licenses/LICENSE-2.0
..
.. Unless required by applicable law or agreed to in writing, software
.. distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
.. WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
.. License for the specific language governing permissions and limitations under
.. the License.

.. _faq/documents:

=========
Documents
=========

Why should I generate my own UUIDs?
-----------------------------------

While CouchDB will generate a unique identifier for the `_id` field of any doc
that you create, there are three reasons why you are, in most cases, better off
generating them yourself.

- If for any reason you miss the 200 OK reply from CouchDB, and storing the
  document is attempted again, you would end up with the same document content
  stored under duplicate ``_id``\ s. This could easily happen with intermediary
  proxies and cache systems that may not inform developers that the failed
  transaction is being retried.
- ``_id``\ s are are the only unique enforced value within CouchDB so you might
  as well make use of this. CouchDB stores its documents in a B+ tree. Each
  additional or updated document is stored as a leaf node, and may require
  re-writing intermediary and parent nodes. You may be able to take advantage of
  sequencing your own ids more effectively than the automatically generated ids
  if you can arrange them to be sequential yourself.

Why use _bulk_docs instead of PUTting single documents to CouchDB?
------------------------------------------------------------------

Aside from the HTTP overhead and roundtrip you are saving, the main advantage is
that CouchDB can handle the B-tree updates more efficiently, decreasing
rewriting of intermediary and parent nodes, both improving speed and saving disk
space.

Why can't I use MVCC in CouchDB as a revision control system for my docs?
-------------------------------------------------------------------------

The revisions CouchDB stores for each document are removed when the database is
compacted. The database may be compacted at any time by a DB admin to save hard
drive space. If you were using those revisions for document versioning, you'd
lose them all upon compaction. In addition, your disk usage would grow with
every document iteration and (if you prevented database compaction) you'd have
no way to recover the used disk space.
