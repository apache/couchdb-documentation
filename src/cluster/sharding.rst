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

Scaling out
===========

Normally you start small and grow over time. In the beginning you might do just
fine with one node, but as your data and number of clients grows, you need to
scale out.

For simplicity we will start fresh and small.

Start node1 and add a database to it. To keep it simple we will have 2 shards
and no replicas.

.. code-block:: bash

    curl -X PUT "http://xxx.xxx.xxx.xxx:5984/small?n=1&q=2" --user daboss

If you look in the directory ``data/shards`` you will find the 2 shards.

.. code-block:: text

    data/
    +-- shards/
    |   +-- 00000000-7fffffff/
    |   |    -- small.1425202577.couch
    |   +-- 80000000-ffffffff/
    |        -- small.1425202577.couch

Now, go to the admin panel

.. code-block:: text

    http://xxx.xxx.xxx.xxx:5986/_utils

and look in the database ``_dbs``, it is here that the metadata for each
database is stored. As the database is called small, there is a document called
small there. Let us look in it. Yes, you can get it with curl too:

.. code-block:: javascript

    curl -X GET "http://xxx.xxx.xxx.xxx:5986/_dbs/small"

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

* ``_id`` The name of the database.
* ``_rev`` The current revision of the metadata.
* ``shard_suffix`` The numbers after small and before .couch. The number of
  seconds after UNIX epoch that the database was created. Stored in ASCII.
* ``changelog`` Self explaining. Only for admins to read.
* ``by_node`` Which shards each node have.
* ``by_rage`` On which nodes each shard is.

Nothing here, nothing there, a shard in my sleeve
-------------------------------------------------

Start node2 and add it to the cluster. Check in ``/_membership`` that the
nodes are talking with each other.

If you look in the directory ``data`` on node2, you will see that there is no
directory called shards.

Go to Fauxton and edit the metadata for small, so it looks like this:

.. code-block:: javascript

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

Then press Save and marvel at the magic. The shards are now on node2 too! We
now have ``n=2``!

If the shards are large, then you can copy them over manually and only have
CouchDB syncing the changes from the last minutes instead.

.. _cluster/sharding/move:

Moving Shards
=============

Add, then delete
----------------

In the world of CouchDB there is no such thing as moving. You can add a new
replica to a shard and then remove the old replica, thereby creating the
illusion of moving. If you try to uphold this illusion with a database that have
``n=1``, you might find yourself in the following scenario:

#. Copy the shard to a new node.
#. Update the metadata to use the new node.
#. Delete the shard on the old node.
#. Lose all writes made between 1 and 2.

As the realty "I added a new replica of the shard X on node Y and then I waited
for them to sync, before I removed the replica of shard X from node Z." is a bit
tedious, people and this documentation tend to use the illusion of moving.

Moving
------

When you get to ``n=3`` you should start moving the shards instead of adding
more replicas.

We will stop on ``n=2`` to keep things simple. Start node number 3 and add it to
the cluster. Then create the directories for the shard on node3:

.. code-block:: bash

    mkdir -p data/shards/00000000-7fffffff

And copy over ``data/shards/00000000-7fffffff/small.1425202577.couch`` from
node1 to node3. Do not move files between the shard directories as that will
confuse CouchDB!

Edit the database document in ``_dbs`` again. Make it so that node3 have a
replica of the shard ``00000000-7fffffff``. Save the document and let CouchDB
sync. If we do not do this, then writes made during the copy of the shard and
the updating of the metadata will only have ``n=1`` until CouchDB has synced.

Then update the metadata document so that node2 no longer have the shard
``00000000-7fffffff``. You can now safely delete
``data/shards/00000000-7fffffff/small.1425202577.couch`` on node 2.

The changelog is nothing that CouchDB cares about, it is only for the admins.
But for the sake of completeness, we will update it again. Use ``delete`` for
recording the removal of the shard ``00000000-7fffffff`` from node2.

Start node4, add it to the cluster and do the same as above with shard
``80000000-ffffffff``.

All documents added during this operation was saved and all reads responded to
without the users noticing anything.

.. _cluster/sharding/views:

Views
=====

The views needs to be moved together with the shards. If you do not, then
CouchDB will rebuild them and this will take time if you have a lot of
documents.

The views are stored in ``data/.shards``.

It is possible to not move the views and let CouchDB rebuild the view every
time you move a shard. As this can take quite some time, it is not recommended.

.. _cluster/sharding/preshard:

Reshard? No, Preshard!
======================

Reshard? Nope. It can not be done. So do not create databases with to few
shards.

If you can not scale out more because you set the number of shards to low, then
you need to create a new cluster and migrate over.

#. Build a cluster with enough nodes to handle one copy of your data.
#. Create a database with the same name, n=1 and with enough shards so you do
   not have to do this again.
#. Set up 2 way replication between the 2 clusters.
#. Let it sync.
#. Tell clients to use both the clusters.
#. Add some nodes to the new cluster and add them as replicas.
#. Remove some nodes from the old cluster.
#. Repeat 6 and 7 until you have enough nodes in the new cluster to have 3
   replicas of every shard.
#. Redirect all clients to the new cluster
#. Turn off the 2 way replication between the clusters.
#. Shut down the old cluster and add the servers as new nodes to the new
   cluster.
#. Relax!

Creating more shards than you need and then move the shards around is called
presharding. The number of shards you need depends on how much data you are
going to store. But creating to many shards increases the complexity without any
real gain. You might even get lower performance. As an example of this, we can
take the author's (15 year) old lab server. It gets noticeably slower with more
than one shard and high load, as the hard drive must seek more.

How many shards you should have depends, as always, on your use case and your
hardware. If you do not know what to do, use the default of 8 shards.
