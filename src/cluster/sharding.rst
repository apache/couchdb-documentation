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

========
Sharding
========

.. _cluster/sharding/scaling-out:

Introduction
------------

A
`shard <https://en.wikipedia.org/wiki/Shard_(database_architecture)>`__
is a horizontal partition of data in a database. Partitioning data into
shards and distributing copies of each shard (called "replicas") to
different nodes in a cluster gives the data greater durability against
node loss. CouchDB clusters automatically shard and distribute data
among nodes, but modifying cluster membership and customizing shard
behavior must be done manually.

Shards and Replicas
~~~~~~~~~~~~~~~~~~~

How many shards and replicas each database has can be set at the global
level, or on a per-database basis. The relevant parameters are *q* and
*n*.

*q* is the number of database shards to maintain. *n* is the number of
copies of each document to distribute. With q=8, the database is split
into 8 shards. With n=3, the cluster distributes three replicas of each
shard. Altogether, that's 24 shards for a single database. In a default
3-node cluster, each node would receive 8 shards. In a 4-node cluster,
each node would receive 6 shards.

CouchDB nodes have a ``etc/default.ini`` file with a section named
``[cluster]`` which looks like this:

::

    [cluster]
    q=8
    n=3

These settings can be modified to set sharding defaults for all
databases, or they can be set on a per-database basis by specifying the
``q`` and ``n`` query parameters when the database is created. For
example:

.. code:: bash

    $ curl -X PUT "$COUCH_URL/database-name?q=4&n=2"

That creates a database that is split into 4 shards and 2 replicas,
yielding 8 shards distributed throughout the cluster.

Quorum
------

When a CouchDB cluster serves reads and writes, it proxies the request
to nodes with relevant shards and responds once enough nodes have
responded to establish
`quorum <https://en.wikipedia.org/wiki/Quorum_(distributed_computing)>`__.
The size of the required quorum can be configured at request time by
setting the ``r`` parameter for document and view reads, and the ``w``
parameter for document writes. For example, here is a request that
specifies that at least two nodes must respond in order to establish
quorum:

.. code:: bash

    $ curl "$COUCH_URL:5984/{docId}?r=2"

Here is a similar example for writing a document:

.. code:: bash

    $ curl -X PUT "$COUCH_URL:5984/{docId}?w=2" -d '{}'

Setting ``r`` or ``w`` to be equal to ``n`` (the number of replicas)
means you will only receive a response once all nodes with relevant
shards have responded, however even this does not guarantee `ACIDic
consistency <https://en.wikipedia.org/wiki/ACID#Consistency>`__. Setting
``r`` or ``w`` to 1 means you will receive a response after only one
relevant node has responded.

Adding a node
-------------

To add a node to a cluster, first you must have the additional node
running somewhere. Make note of the address it binds to, like
``127.0.0.1``, then ``PUT`` an empty document to the ``/_node``
endpoint:

.. code:: bash

    $ curl -X PUT "$COUCH_URL:5984/_node/{name}@{address}" -d '{}'

This will add the node to the cluster. Existing shards will not be moved
or re-balanced in response to the addition, but future operations will
distribute shards to the new node.

Now when you GET the ``/_membership`` endpoint, you will see the new
node.

Removing a node
---------------

To remove a node from the cluster, you must first acquire the ``_rev``
value for the document that signifies its existence:

.. code:: bash

    $ curl "$COUCH_URL:5984/_node/{name}@{address}"
    {"_id":"{name}@{address}","_rev":"{rev}"}

Using that ``_rev``, you can delete the node using the ``/_node``
endpoint:

.. code:: bash

    $ curl -X DELETE "$COUCH_URL:5984/_node/{name}@{address}?rev={rev}"

.. raw:: html

   <div class="alert alert-warning">

**Note**: Before you remove a node, make sure to
`move its shards <#moving-a-shard>`__
or else they will be lost.

Moving a shard
--------------

Moving shards between nodes involves the following steps:

1. Copy the shard file onto the new node.
2. Update cluster metadata to reflect the move.
3. Replicate from the old to the new to catch any changes.
4. Delete the old shard file.

Copying shard files
~~~~~~~~~~~~~~~~~~~

Shard files live in the ``data/shards`` directory of your CouchDB
install. Since they are just files, you can use ``cp``, ``rsync``,
``scp`` or other command to copy them from one node to another. For
example:

.. code:: bash

    # one one machine
    mkdir -p data/shards/{range}
    # on the other
    scp $COUCH_PATH/data/shards/{range}/{database}.{timestamp}.couch $OTHER:$COUCH_PATH/data/shards/{range}/

Views are also sharded, and their shards should be moved to save the new
node the effort of rebuilding the view. View shards live in
``data/.shards``.

Updating cluster metadata
~~~~~~~~~~~~~~~~~~~~~~~~~

To update the cluster metadata, use the special node-specific ``/_dbs``
database, accessible via a node's private port, usually at port 5986.
First, retrieve the database's current metadata:

.. code:: bash

    $ curl $COUCH_URL:5986/_dbs/{name}

    {
        "_id": "{name}",
        "_rev": "1-5e2d10c29c70d3869fb7a1fd3a827a64",
        "shard_suffix": [
            46,
            49,
            52,
            50,
            53,
            50,
            48,
            50,
            53,
            55,
            55
        ],
        "changelog": [
        [
            "add",
            "00000000-7fffffff",
            "node1@xxx.xxx.xxx.xxx"
        ],
        [
            "add",
            "80000000-ffffffff",
            "node1@xxx.xxx.xxx.xxx"
        ]
        ],
        "by_node": {
            "node1@xxx.xxx.xxx.xxx": [
                "00000000-7fffffff",
                "80000000-ffffffff"
            ]
        },
        "by_range": {
            "00000000-7fffffff": [
                "node1@xxx.xxx.xxx.xxx"
            ],
            "80000000-ffffffff": [
                "node1@xxx.xxx.xxx.xxx"
            ]
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

As of this writing, this process must be done manually. **WARNING: Be
very careful! Mistakes during this process can irreperably corrupt the
cluster!**

To add a shard to a node, add entries like this to the database
metadata's ``changelog`` attribute:

.. code:: json1

    [
        "add",
        "{range}",
        "{name}@{address}"
    ]

*Note*: You can remove a node by specifying 'remove' instead of 'add'.

Once you have figured out the new changelog entries, you will need to
update the ``by_node`` and ``by_range`` to reflect who is storing what
shards. The data in the changelog entries and these attributes must
match. If they do not, the database may become corrupted.

As an example, here is an updated version of the metadata above that
adds shards to a second node called ``node2``:

.. code:: json

    {
        "_id": "small",
        "_rev": "1-5e2d10c29c70d3869fb7a1fd3a827a64",
        "shard_suffix": [
            46,
            49,
            52,
            50,
            53,
            50,
            48,
            50,
            53,
            55,
            55
        ],
        "changelog": [
        [
            "add",
            "00000000-7fffffff",
            "node1@xxx.xxx.xxx.xxx"
        ],
        [
            "add",
            "80000000-ffffffff",
            "node1@xxx.xxx.xxx.xxx"
        ],
        [
            "add",
            "00000000-7fffffff",
            "node2@yyy.yyy.yyy.yyy"
        ],
        [
            "add",
            "80000000-ffffffff",
            "node2@yyy.yyy.yyy.yyy"
        ]
        ],
        "by_node": {
            "node1@xxx.xxx.xxx.xxx": [
                "00000000-7fffffff",
                "80000000-ffffffff"
            ],
            "node2@yyy.yyy.yyy.yyy": [
                "00000000-7fffffff",
                "80000000-ffffffff"
            ]
        },
        "by_range": {
            "00000000-7fffffff": [
                "node1@xxx.xxx.xxx.xxx",
                "node2@yyy.yyy.yyy.yyy"
            ],
            "80000000-ffffffff": [
                "node1@xxx.xxx.xxx.xxx",
                "node2@yyy.yyy.yyy.yyy"
            ]
        }
    }

Now you can ``PUT`` this new metadata:

.. code:: bash

    $ curl -X PUT $COUCH_URL:5986/_dbs/{name} -d '{...}'

Replicating from old to new
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Because shards are just CouchDB databases, you can replicate them
around. In order to make sure the new shard receives any updates the old
one processed while you were updating its metadata, you should replicate
the old shard to the new one:

::

    $ curl -X POST $COUCH_URL:5986/_replicate -d '{ \
        "source": $OLD_SHARD_URL,
        "target": $NEW_SHARD_URL
        }'

This will bring the new shard up to date so that we can safely delete
the old one.

Delete old shard
~~~~~~~~~~~~~~~~

You can remove the old shard either by deleting its file or by deleting
it through the private 5986 port:

.. code:: bash

    # delete the file
    rm $COUCH_DIR/data/shards/$OLD_SHARD

    # OR delete the database
    curl -X DELETE $COUCH_URL:5986/$OLD_SHARD

Congratulations! You have manually added a new shard. By adding and
removing database shards in this way, they can be moved between nodes.

Specifying database placement
-----------------------------

Database shards can be configured to live solely on specific nodes using
placement rules.

First, each node must be labeled with a zone attribute. This defines
which zone each node is in. You do this by editing the node’s document
in the ``/nodes`` database, which is accessed through the “back-door”
(5986) port. Add a key value pair of the form:

::

    "zone": "{zone-name}"

Do this for all of the nodes in your cluster. For example:

.. code:: bash

    $ curl -X PUT $COUCH_URL:5986/_nodes/{name}@{address} \
        -d '{ \
            "_id": "{name}@{address}",
            "_rev": "{rev}",
            "zone": "{zone-name}"
            }'

In the config file (local.ini or default.ini) of each node, define a
consistent cluster-wide setting like:

::

    [cluster]
    placement = {zone-name-1}:2,{zone-name-2}:1

In this example, it will ensure that two replicas for a shard will be
hosted on nodes with the zone attribute set to ``{zone-name-1}`` and one
replica will be hosted on a new with the zone attribute set to
``{zone-name-2}``.

Note that you can also use this system to ensure certain nodes in the
cluster do not host any replicas for newly created databases, by giving
them a zone attribute that does not appear in the ``[cluster]``
placement string.

You can also specify zones on a per-database basis by specifying the
zone as a query parameter when the database is created:

.. code:: bash

    curl -X PUT $COUCH_URL:5984/{dbName}?zone={zone}

Resharding
----------

Shard settings for databases can only be set when the database is
created, precluding live resharding. Instead, to reshard a database, it
must be regenerated. Here are the steps:

1. Create a temporary database with the desired shard settings.
2. Replicate the primary database to the temporary. Multiple
   replications may be required if the primary database is under active
   use.
3. Delete the primary database. **Make sure nobody is using it!**
4. Recreate the primary database with the desired shard settings.
5. Replicate the temporary back to the primary.
6. Delete the temporary database.

Once all steps have completed, the database can be used again. The
cluster will create and distribute its shards according to placement
rules automatically.
