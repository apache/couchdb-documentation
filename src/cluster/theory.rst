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

.. _cluster/theory:

======
Theory
======

Before we move on, we need some theory.

As you see in ``etc/default.ini`` there is a section called [cluster]

.. code-block:: text

    [cluster]
    q=8
    n=3

* ``q`` - The number of shards.
* ``n`` - The number of copies there is of every document. Replicas.

When creating a database you can send your own values with request and
thereby override the defaults in ``default.ini``.

The number of copies of a document with the same revision that have to be read
before CouchDB returns with a ``200`` is equal to a half of total copies of
the document plus one *in the current partition*. That is, if there is a network
partition and, for example, only 1 out of 3 nodes is available you can still
get a ``200`` response but the data will not have come from a true quorum and
might be stale.

The number of nodes that need to save a document before a write is returned with
``201`` is also equal to half of the total copies of the document plus one.
However, unlike the read case, for writes this is computed for the database as a
whole, even if there is a network partition. If there are fewer nodes than that
number, then ``202`` is returned. Both read and write numbers can be specified
with a request as ``r`` and ``w`` parameters accordingly.

We will focus on the shards and replicas for now.

A shard is a part of a database. The more shards, the more you can scale out.
If you have 4 shards, that means that you can have at most 4 nodes. With one
shard you can have only one node, just the way CouchDB 1.x is.

Replicas adds fail resistance, as some nodes can be offline without everything
comes crashing down.

* ``n=1`` All nodes must be up.
* ``n=2`` Any 1 node can be down.
* ``n=3`` Any 2 nodes can be down.
* etc

Computers go down and sysadmins pull out network cables in a furious rage from
time to time, so using ``n<2`` is asking for downtime. Having too high a value
of ``n`` adds servers and complexity without any real benefit. The sweet spot is
at ``n=3``.

Say that we have a database with 3 replicas and 4 shards. That would give us a
maximum of 12 nodes. 4*3=12 Every shard have 3 copies.

We can lose any 2 nodes and still read and write all documents.

What happens if we lose more nodes? It depends on how lucky we are. As long as
there is at least one copy of every shard online, we can read and write all
documents.

So, if we are very lucky then we can lose 8 nodes at maximum.
