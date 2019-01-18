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

.. _cluster/sharding:

================
Shard Management
================

.. _cluster/sharding/intro:

Introduction
------------

This document discusses how sharding works in CouchDB along with how to
safely add, move, remove, and create placement rules for shards and
shard replicas.

A `shard
<https://en.wikipedia.org/wiki/Shard_(database_architecture)>`__ is a
horizontal partition of data in a database. Partitioning data into
shards and distributing copies of each shard (called "shard replicas" or
just "replicas") to different nodes in a cluster gives the data greater
durability against node loss. CouchDB clusters automatically shard
databases and distribute the subsets of documents that compose each
shard among nodes. Modifying cluster membership and sharding behavior
must be done manually.

Shards and Replicas
~~~~~~~~~~~~~~~~~~~

How many shards and replicas each database has can be set at the global
level, or on a per-database basis. The relevant parameters are ``q`` and
``n``.

*q* is the number of database shards to maintain. *n* is the number of
copies of each document to distribute. The default value for ``n`` is ``3``,
and for ``q`` is ``8``. With ``q=8``, the database is split into 8 shards. With
``n=3``, the cluster distributes three replicas of each shard. Altogether,
that's 24 shard replicas for a single database. In a default 3-node cluster,
each node would receive 8 shards. In a 4-node cluster, each node would
receive 6 shards. We recommend in the general case that the number of
nodes in your cluster should be a multiple of ``n``, so that shards are
distributed evenly.

CouchDB nodes have a ``etc/local.ini`` file with a section named
`cluster <../config/cluster.html>`__ which looks like this:

::

    [cluster]
    q=8
    n=3

These settings can be modified to set sharding defaults for all
databases, or they can be set on a per-database basis by specifying the
``q`` and ``n`` query parameters when the database is created. For
example:

.. code-block:: bash

    $ curl -X PUT "$COUCH_URL:5984/database-name?q=4&n=2"

That creates a database that is split into 4 shards and 2 replicas,
yielding 8 shard replicas distributed throughout the cluster.

Quorum
~~~~~~

Depending on the size of the cluster, the number of shards per database,
and the number of shard replicas, not every node may have access to
every shard, but every node knows where all the replicas of each shard
can be found through CouchDB's internal shard map.

Each request that comes in to a CouchDB cluster is handled by any one
random coordinating node. This coordinating node proxies the request to
the other nodes that have the relevant data, which may or may not
include itself. The coordinating node sends a response to the client
once a `quorum
<https://en.wikipedia.org/wiki/Quorum_(distributed_computing)>`__ of
database nodes have responded; 2, by default. The default required size
of a quorum is equal to ``r=w=((n+1)/2)`` where ``r`` refers to the size
of a read quorum, ``w`` refers to the size of a write quorum, and ``n``
refers to the number of replicas of each shard. In a default cluster where
``n`` is 3, ``((n+1)/2)`` would be 2.

.. note::
    Each node in a cluster can be a coordinating node for any one
    request. There are no special roles for nodes inside the cluster.

The size of the required quorum can be configured at request time by
setting the ``r`` parameter for document and view reads, and the ``w``
parameter for document writes. For example, here is a request that
directs the coordinating node to send a response once at least two nodes
have responded:

.. code-block:: bash

    $ curl "$COUCH_URL:5984/<db>/<doc>?r=2"

Here is a similar example for writing a document:

.. code-block:: bash

    $ curl -X PUT "$COUCH_URL:5984/<db>/<doc>?w=2" -d '{...}'

Setting ``r`` or ``w`` to be equal to ``n`` (the number of replicas)
means you will only receive a response once all nodes with relevant
shards have responded or timed out, and as such this approach does not
guarantee `ACIDic consistency
<https://en.wikipedia.org/wiki/ACID#Consistency>`__. Setting ``r`` or
``w`` to 1 means you will receive a response after only one relevant
node has responded.

.. _cluster/sharding/examine:

Examining database shards
-------------------------

There are a few API endpoints that help you understand how a database
is sharded. Let's start by making a new database on a cluster, and putting
a couple of documents into it:

.. code-block:: bash

    $ curl -X PUT $COUCH_URL:5984/mydb
    {"ok":true}
    $ curl -X PUT $COUCH_URL:5984/mydb/joan -d '{"loves":"cats"}'
    {"ok":true,"id":"joan","rev":"1-cc240d66a894a7ee7ad3160e69f9051f"}
    $ curl -X PUT $COUCH_URL:5984/mydb/robert -d '{"loves":"dogs"}'
    {"ok":true,"id":"robert","rev":"1-4032b428c7574a85bc04f1f271be446e"}

First, the top level :ref:`api/db` endpoint will tell you what the sharding parameters
are for your database:

.. code-block:: bash

    $ curl -s $COUCH_URL:5984/db | jq .
    {
      "db_name": "mydb",
    ...
      "cluster": {
        "q": 8,
        "n": 3,
        "w": 2,
        "r": 2
      },
    ...
    }

So we know this database was created with 8 shards (``q=8``), and each
shard has 3 replicas (``n=3``) for a total of 24 shard replicas across
the nodes in the cluster.

Now, let's see how those shard replicas are placed on the cluster with
the :ref:`api/db/shards` endpoint:

.. code-block:: bash

    $ curl -s $COUCH_URL:5984/mydb/_shards | jq .
    {
      "shards": {
        "00000000-1fffffff": [
          "node1@127.0.0.1",
          "node2@127.0.0.1",
          "node4@127.0.0.1"
        ],
        "20000000-3fffffff": [
          "node1@127.0.0.1",
          "node2@127.0.0.1",
          "node3@127.0.0.1"
        ],
        "40000000-5fffffff": [
          "node2@127.0.0.1",
          "node3@127.0.0.1",
          "node4@127.0.0.1"
        ],
        "60000000-7fffffff": [
          "node1@127.0.0.1",
          "node3@127.0.0.1",
          "node4@127.0.0.1"
        ],
        "80000000-9fffffff": [
          "node1@127.0.0.1",
          "node2@127.0.0.1",
          "node4@127.0.0.1"
        ],
        "a0000000-bfffffff": [
          "node1@127.0.0.1",
          "node2@127.0.0.1",
          "node3@127.0.0.1"
        ],
        "c0000000-dfffffff": [
          "node2@127.0.0.1",
          "node3@127.0.0.1",
          "node4@127.0.0.1"
        ],
        "e0000000-ffffffff": [
          "node1@127.0.0.1",
          "node3@127.0.0.1",
          "node4@127.0.0.1"
        ]
      }
    }

Now we see that there are actually 4 nodes in this cluster, and CouchDB
has spread those 24 shard replicas evenly across all 4 nodes.

We can also see exactly which shard contains a given document with
the :ref:`api/db/shards/doc` endpoint:

.. code-block:: bash

    $ curl -s $COUCH_URL:5984/mydb/_shards/joan | jq .
    {
      "range": "e0000000-ffffffff",
      "nodes": [
        "node1@127.0.0.1",
        "node3@127.0.0.1",
        "node4@127.0.0.1"
      ]
    }
    $ curl -s $COUCH_URL:5984/mydb/_shards/robert | jq .
    {
      "range": "60000000-7fffffff",
      "nodes": [
        "node1@127.0.0.1",
        "node3@127.0.0.1",
        "node4@127.0.0.1"
      ]
    }

CouchDB shows us the specific shard into which each of the two sample
documents is mapped.

.. _cluster/sharding/move:

Moving a shard
--------------

This section describes how to manually place and replace shards. These
activities are critical steps when you determine your cluster is too big
or too small, and want to resize it successfully, or you have noticed
from server metrics that database/shard layout is non-optimal and you
have some "hot spots" that need resolving.

Consider a three-node cluster with q=8 and n=3. Each database has 24
shards, distributed across the three nodes. If you :ref:`add a fourth
node <cluster/nodes/add>` to the cluster, CouchDB will not redistribute
existing database shards to it. This leads to unbalanced load, as the
new node will only host shards for databases created after it joined the
cluster. To balance the distribution of shards from existing databases,
they must be moved manually.

Moving shards between nodes in a cluster involves the following steps:

0. :ref:`Ensure the target node has joined the cluster <cluster/nodes/add>`.
1. Copy the shard(s) and any secondary
   :ref:`index shard(s) onto the target node <cluster/sharding/copying>`.
2. :ref:`Set the target node to maintenance mode <cluster/sharding/mm>`.
3. Update cluster metadata
   :ref:`to reflect the new target shard(s) <cluster/sharding/add-shard>`.
4. Monitor internal replication
   :ref:`to ensure up-to-date shard(s) <cluster/sharding/verify>`.
5. :ref:`Clear the target node's maintenance mode <cluster/sharding/mm-2>`.
6. Update cluster metadata again
   :ref:`to remove the source shard(s)<cluster/sharding/remove-shard>`
7. Remove the shard file(s) and secondary index file(s)
   :ref:`from the source node <cluster/sharding/remove-shard-files>`.

.. _cluster/sharding/copying:

Copying shard files
~~~~~~~~~~~~~~~~~~~

.. note::
    Technically, copying database and secondary index
    shards is optional. If you proceed to the next step without
    performing this data copy, CouchDB will use internal replication
    to populate the newly added shard replicas. However, copying files
    is faster than internal replication, especially on a busy cluster,
    which is why we recommend performing this manual data copy first.

Shard files live in the ``data/shards`` directory of your CouchDB
install. Within those subdirectories are the shard files themselves. For
instance, for a ``q=8`` database called ``abc``, here is its database shard
files:

::

  data/shards/00000000-1fffffff/abc.1529362187.couch
  data/shards/20000000-3fffffff/abc.1529362187.couch
  data/shards/40000000-5fffffff/abc.1529362187.couch
  data/shards/60000000-7fffffff/abc.1529362187.couch
  data/shards/80000000-9fffffff/abc.1529362187.couch
  data/shards/a0000000-bfffffff/abc.1529362187.couch
  data/shards/c0000000-dfffffff/abc.1529362187.couch
  data/shards/e0000000-ffffffff/abc.1529362187.couch

Secondary indexes (including JavaScript views, Erlang views and Mango
indexes) are also sharded, and their shards should be moved to save the
new node the effort of rebuilding the view. View shards live in
``data/.shards``. For example:

::

  data/.shards
  data/.shards/e0000000-ffffffff/_replicator.1518451591_design
  data/.shards/e0000000-ffffffff/_replicator.1518451591_design/mrview
  data/.shards/e0000000-ffffffff/_replicator.1518451591_design/mrview/3e823c2a4383ac0c18d4e574135a5b08.view
  data/.shards/c0000000-dfffffff
  data/.shards/c0000000-dfffffff/_replicator.1518451591_design
  data/.shards/c0000000-dfffffff/_replicator.1518451591_design/mrview
  data/.shards/c0000000-dfffffff/_replicator.1518451591_design/mrview/3e823c2a4383ac0c18d4e574135a5b08.view
  ...

Since they are files, you can use ``cp``, ``rsync``,
``scp`` or other file-copying command to copy them from one node to
another. For example:

.. code-block:: bash

    # one one machine
    $ mkdir -p data/.shards/<range>
    $ mkdir -p data/shards/<range>
    # on the other
    $ scp <couch-dir>/data/.shards/<range>/<database>.<datecode>* \
      <node>:<couch-dir>/data/.shards/<range>/
    $ scp <couch-dir>/data/shards/<range>/<database>.<datecode>.couch \
      <node>:<couch-dir>/data/shards/<range>/

.. note::
    Remember to move view files before database files! If a view index
    is ahead of its database, the database will rebuild it from
    scratch.

.. _cluster/sharding/mm:

Set the target node to ``true`` maintenance mode
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before telling CouchDB about these new shards on the node, the node
must be put into maintenance mode. Maintenance mode instructs CouchDB to
return a ``404 Not Found`` response on the ``/_up`` endpoint, and
ensures it does not participate in normal interactive clustered requests
for its shards. A properly configured load balancer that uses ``GET
/_up`` to check the health of nodes will detect this 404 and remove the
node from circulation, preventing requests from being sent to that node.
For example, to configure HAProxy to use the ``/_up`` endpoint, use:

::

  http-check disable-on-404
  option httpchk GET /_up

If you do not set maintenance mode, or the load balancer ignores this
maintenance mode status, after the next step is performed the cluster
may return incorrect responses when consulting the node in question. You
don't want this! In the next steps, we will ensure that this shard is
up-to-date before allowing it to participate in end-user requests.

To enable maintenance mode:

.. code-block:: bash

    $ curl -X PUT -H "Content-type: application/json" \
        $COUCH_URL:5984/_node/<nodename>/_config/couchdb/maintenance_mode \
        -d "\"true\""

Then, verify that the node is in maintenance mode by performing a ``GET
/_up`` on that node's individual endpoint:

.. code-block:: bash

    $ curl -v $COUCH_URL/_up
    …
    < HTTP/1.1 404 Object Not Found
    …
    {"status":"maintenance_mode"}

Finally, check that your load balancer has removed the node from the
pool of available backend nodes.

.. _cluster/sharding/add-shard:

Updating cluster metadata to reflect the new target shard(s)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now we need to tell CouchDB that the target node (which must already be
:ref:`joined to the cluster <cluster/nodes/add>`) should be hosting
shard replicas for a given database.

To update the cluster metadata, use the special ``/_dbs`` database,
which is an internal CouchDB database that maps databases to shards and
nodes. This database is replicated between nodes. It is accessible only
via a node-local port, usually at port 5986. By default, this port is
only available on the localhost interface for security purposes.

First, retrieve the database's current metadata:

.. code-block:: bash

    $ curl http://localhost:5986/_dbs/{name}
    {
      "_id": "{name}",
      "_rev": "1-e13fb7e79af3b3107ed62925058bfa3a",
      "shard_suffix": [46, 49, 53, 51, 48, 50, 51, 50, 53, 50, 54],
      "changelog": [
        ["add", "00000000-1fffffff", "node1@xxx.xxx.xxx.xxx"],
        ["add", "00000000-1fffffff", "node2@xxx.xxx.xxx.xxx"],
        ["add", "00000000-1fffffff", "node3@xxx.xxx.xxx.xxx"],
        …
      ],
      "by_node": {
        "node1@xxx.xxx.xxx.xxx": [
          "00000000-1fffffff",
          …
        ],
        …
      },
      "by_range": {
        "00000000-1fffffff": [
          "node1@xxx.xxx.xxx.xxx",
          "node2@xxx.xxx.xxx.xxx",
          "node3@xxx.xxx.xxx.xxx"
        ],
        …
      }
    }

Here is a brief anatomy of that document:

-  ``_id``: The name of the database.
-  ``_rev``: The current revision of the metadata.
-  ``shard_suffix``: A timestamp of the database's creation, marked as
   seconds after the Unix epoch mapped to the codepoints for ASCII
   numerals.
-  ``changelog``: History of the database's shards.
-  ``by_node``: List of shards on each node.
-  ``by_range``: On which nodes each shard is.

To reflect the shard move in the metadata, there are three steps:

1. Add appropriate changelog entries.
2. Update the ``by_node`` entries.
3. Update the ``by_range`` entries.

.. warning::
    Be very careful! Mistakes during this process can
    irreparably corrupt the cluster!

As of this writing, this process must be done manually.

To add a shard to a node, add entries like this to the database
metadata's ``changelog`` attribute:

.. code-block:: javascript

    ["add", "<range>", "<node-name>"]

The ``<range>`` is the specific shard range for the shard. The ``<node-
name>`` should match the name and address of the node as displayed in
``GET /_membership`` on the cluster.

.. note::
    When removing a shard from a node, specify ``remove`` instead of ``add``.

Once you have figured out the new changelog entries, you will need to
update the ``by_node`` and ``by_range`` to reflect who is storing what
shards. The data in the changelog entries and these attributes must
match. If they do not, the database may become corrupted.

Continuing our example, here is an updated version of the metadata above
that adds shards to an additional node called ``node4``:

.. code-block:: javascript

    {
      "_id": "{name}",
      "_rev": "1-e13fb7e79af3b3107ed62925058bfa3a",
      "shard_suffix": [46, 49, 53, 51, 48, 50, 51, 50, 53, 50, 54],
      "changelog": [
        ["add", "00000000-1fffffff", "node1@xxx.xxx.xxx.xxx"],
        ["add", "00000000-1fffffff", "node2@xxx.xxx.xxx.xxx"],
        ["add", "00000000-1fffffff", "node3@xxx.xxx.xxx.xxx"],
        ...
        ["add", "00000000-1fffffff", "node4@xxx.xxx.xxx.xxx"]
      ],
      "by_node": {
        "node1@xxx.xxx.xxx.xxx": [
          "00000000-1fffffff",
          ...
        ],
        ...
        "node4@xxx.xxx.xxx.xxx": [
          "00000000-1fffffff"
        ]
      },
      "by_range": {
        "00000000-1fffffff": [
          "node1@xxx.xxx.xxx.xxx",
          "node2@xxx.xxx.xxx.xxx",
          "node3@xxx.xxx.xxx.xxx",
          "node4@xxx.xxx.xxx.xxx"
        ],
        ...
      }
    }

Now you can ``PUT`` this new metadata:

.. code-block:: bash

    $ curl -X PUT http://localhost:5986/_dbs/{name} -d '{...}'

.. _cluster/sharding/sync:

Forcing synchronization of the shard(s)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. versionadded:: 2.4.0

Whether you pre-copied shards to your new node or not, you can force
CouchDB to synchronize all replicas of all shards in a database with the
:ref:`api/db/sync_shards` endpoint:

.. code-block:: bash

    $ curl -X POST $COUCH_URL:5984/{dbname}/_sync_shards
    {"ok":true}

This starts the synchronization process. Note that this will put
additional load onto your cluster, which may affect performance.

It is also possible to force synchronization on a per-shard basis by
writing to a document that is stored within that shard.

.. note::

    Admins may want to bump their ``[mem3] sync_concurrency`` value to a
    larger figure for the duration of the shards sync.

.. _cluster/sharding/verify:

Monitor internal replication to ensure up-to-date shard(s)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After you complete the previous step, CouchDB will have started
synchronizing the shards. You can observe this happening by monitoring
the ``/_node/<nodename>/_system`` endpoint, which includes the
``internal_replication_jobs`` metric.

Once this metric has returned to the baseline from before you started
the shard sync, or is ``0``, the shard replica is ready to serve data
and we can bring the node out of maintenance mode.

.. _cluster/sharding/mm-2:

Clear the target node's maintenance mode
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can now let the node start servicing data requests by
putting ``"false"`` to the maintenance mode configuration endpoint, just
as in step 2.

Verify that the node is not in maintenance mode by performing a ``GET
/_up`` on that node's individual endpoint.

Finally, check that your load balancer has returned the node to the pool
of available backend nodes.

.. _cluster/sharding/remove-shard:

Update cluster metadata again to remove the source shard
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now, remove the source shard from the shard map the same way that you
added the new target shard to the shard map in step 2. Be sure to add
the ``["remove", <range>, <source-shard>]`` entry to the end of the
changelog as well as modifying both the ``by_node`` and ``by_range`` sections of
the database metadata document.

.. _cluster/sharding/remove-shard-files:

Remove the shard and secondary index files from the source node
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Finally, you can remove the source shard replica by deleting its file from the
command line on the source host, along with any view shard replicas:

.. code-block:: bash

    $ rm <couch-dir>/data/shards/<range>/<dbname>.<datecode>.couch
    $ rm -r <couch-dir>/data/.shards/<range>/<dbname>.<datecode>*

Congratulations! You have moved a database shard replica. By adding and removing
database shard replicas in this way, you can change the cluster's shard layout,
also known as a shard map.

Specifying database placement
-----------------------------

You can configure CouchDB to put shard replicas on certain nodes at
database creation time using placement rules.

First, each node must be labeled with a zone attribute. This defines
which zone each node is in. You do this by editing the node’s document
in the ``/_nodes`` database, which is accessed through the node-local
port. Add a key value pair of the form:

::

    "zone": "{zone-name}"

Do this for all of the nodes in your cluster. For example:

.. code-block:: bash

    $ curl -X PUT http://localhost:5986/_nodes/<node-name> \
        -d '{ \
            "_id": "<node-name>",
            "_rev": "<rev>",
            "zone": "<zone-name>"
            }'

In the local config file (``local.ini``) of each node, define a
consistent cluster-wide setting like:

::

    [cluster]
    placement = <zone-name-1>:2,<zone-name-2>:1

In this example, CouchDB will ensure that two replicas for a shard will
be hosted on nodes with the zone attribute set to ``<zone-name-1>`` and
one replica will be hosted on a new with the zone attribute set to
``<zone-name-2>``.

This approach is flexible, since you can also specify zones on a per-
database basis by specifying the placement setting as a query parameter
when the database is created, using the same syntax as the ini file:

.. code-block:: bash

    curl -X PUT $COUCH_URL:5984/<dbname>?zone=<zone>

Note that you can also use this system to ensure certain nodes in the
cluster do not host any replicas for newly created databases, by giving
them a zone attribute that does not appear in the ``[cluster]``
placement string.

Resharding a database to a new q value
--------------------------------------

The ``q`` value for a database can only be set when the database is
created, precluding live resharding. Instead, to reshard a database, it
must be regenerated. Here are the steps:

1. Create a temporary database with the desired shard settings, by
   specifying the q value as a query parameter during the PUT
   operation.
2. Stop clients accessing the database.
3. Replicate the primary database to the temporary one. Multiple
   replications may be required if the primary database is under
   active use.
4. Delete the primary database. **Make sure nobody is using it!**
5. Recreate the primary database with the desired shard settings.
6. Clients can now access the database again.
7. Replicate the temporary back to the primary.
8. Delete the temporary database.

Once all steps have completed, the database can be used again. The
cluster will create and distribute its shards according to placement
rules automatically.

Downtime can be avoided in production if the client application(s) can
be instructed to use the new database instead of the old one, and a cut-
over is performed during a very brief outage window.
