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

.. _cluster/databases:

===================
Database Management
===================

.. _cluster/databases/create:

Creating a database
===================

This will create a database with ``3`` replicas and ``8`` shards.

.. code-block:: bash

    curl -X PUT "http://xxx.xxx.xxx.xxx:5984/database-name?n=3&q=8" --user admin-user

The database is in ``data/shards``. Look around on all the nodes and you will
find all the parts.

If you do not specify ``n`` and ``q`` the default will be used. The default is
``3`` replicas and ``8`` shards.

.. _cluster/databases/delete:

Deleteing a database
====================

.. code-block:: bash

    curl -X DELETE "http://xxx.xxx.xxx.xxx:5984/database-name --user admin-user

Placing a database on specific nodes
====================================

In BigCouch, the predecessor to CouchDB 2.0's clustering functionality, there
was the concept of zones. CouchDB 2.0 carries this forward with cluster
placement rules.

First, each node must be labelled with a zone attribute. This defines the zone
where the node is located. In CouchDB 2.2.0 and later this can be accomplished
by setting the ``[node] zone`` configuration property in a .ini config file
(e.g. default.ini or local.ini). In older versions it is necessary to edit the
node's document in the ``/_nodes`` database directly, accessing it through the
"back-door" (5986) port. The direct ``/_nodes`` database approach is still
supported in 2.2.0, but if there is a conflict between the entry in ``/_nodes``
and the one in the config the latter will take precedence (and the entry in the
database will be overwritten). An example zone attribute might take the form:

.. code-block:: text

    "zone": "metro-dc-a"

Set this attribute as appropriate for all of the nodes in your cluster.

In your config file (local.ini or default.ini) on each node, define a
consistent cluster-wide setting like:

.. code-block:: text

    [cluster]
    placement = metro-dc-a:2,metro-dc-b:1

In this example, it will ensure that two replicas for a shard will be hosted
on nodes with the zone attribute set to ``metro-dc-a`` and one replica will
be hosted on a new wiht the zone attribute set to ``metro-dc-b``.

Note that you can also use this system to ensure certain nodes in the cluster
do not host *any* replicas for newly created databases, by giving them a zone
attribute that does not appear in the ``[cluster]`` placement string.
