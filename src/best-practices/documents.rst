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

.. _best-practices/documents:

==============================
Document Design Considerations
==============================

When designing your database, and your document structure, there are a number of
best practices to take into consideration. Especially for people accustomed to
relational databases, some of these techniques may be non-obvious.

Don't rely on CouchDB's auto-UUID generation
--------------------------------------------

While CouchDB will generate a unique identifier for the ``_id`` field of any doc
that you create, in most cases you are better off generating them yourself for
a few reasons:

- If for any reason you miss the ``200 OK`` reply from CouchDB, and storing the
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

Alternatives to auto-incrementing sequences
-------------------------------------------

Because of replication, as well as the distributed nature of CouchDB, it is not
practical to use auto-incrementing sequences with CouchDB. These are often used
to ensure unique identifiers for each row in a database table. CouchDB generates
unique ids on its own and you can specify your own as well, so you don't really
need a sequence here. If you use a sequence for something else, you will be
better off finding another way to express it in CouchDB in another way.
