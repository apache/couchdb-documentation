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

In clustered operation, a quorum must be reached before CouchDB returns a
``200`` for a fetch, or ``201`` for a write operation. A quorum is defined as
one plus half the number of "relevant copies". "Relevant copies" is defined
slightly differently for read and write operations.

For read operations, the number of relevant copies is the number of
currently-accessible shards holding the requested data, meaning that in the case
of a failure or network partition, the number of relevant copies may be lower
than the number of replicas in the cluster.  The number of read copies can be
set with the ``r`` parameter.

For write operations the number of relevant copies is always ``n``, the number
of replicas in the cluster.  For write operations, the number of copies can be
set using the w parameter. If fewer than this number of nodes is available, a
``202`` will be returned.

We will focus on the shards and replicas for now.

A shard is a part of a database. It can be replicated multiple times. The more
copies of a shard, the more you can scale out. If you have 4 replicas, that
means that all 4 copies of this specific shard will live on at most 4 nodes.
With one replica you can have only one node, just as with CouchDB 1.x.
No node can have more than one copy of each shard replica. The default for
CouchDB since 2.0.0 is ``q=8`` and ``n=3``, meaning each database (and secondary
index) is split into 8 shards, with 3 replicas per shard, for a total of 24
shard replica files. For a CouchDB cluster only hosting a single database with
these default values, a maximum of 24 nodes can be used to scale horizontally.

Replicas add failure resistance, as some nodes can be offline without everything
crashing down.

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
