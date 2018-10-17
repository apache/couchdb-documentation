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

.. default-domain:: config
.. highlight:: ini

======================
Configuring Clustering
======================

.. _config/cluster:

Cluster Options
===============

.. config:section:: cluster :: cluster Options

    .. config:option:: q

    Sets the default number of shards for newly created databases. The
    default value, ``8``, splits a database into 8 separate partitions. ::

        [cluster]
        q = 8

    For systems with lots of small, infrequently accessed databases, or
    for servers with fewer CPU cores, consider reducing this value to
    ``1`` or ``2``.

    The value of ``q`` can also be overridden on a per-DB basis, at DB
    creation time.

    .. seealso::
        httpdomain:put:`PUT /{db} </{db}>`

    .. config:option:: n

    Sets the number of replicas of each document in a cluster. CouchDB will
    only place one replica per node in a cluster. When set up through the
    :ref:`Cluster Setup Wizard <cluster/setup/wizard>`, a standalone single
    node will have ``n = 1``, a two node cluster will have ``n = 2``, and
    any larger cluster will have ``n = 3``. It is recommended not to set
    ``n`` greater than ``3``. ::

        [cluster]
        n = 3

    .. config:option:: placement

    Sets the cluster-wide replica placement policy when creating new
    databases. The value must be a comma-delimited list of strings of the
    format ``zone_name:#``, where ``zone_name`` is a zone as specified in
    the ``nodes`` database and ``#`` is an integer indicating the number of
    replicas to place on nodes with a matching ``zone_name``.

    This parameter is not specified by default. ::

        [cluster]
        placement = metro-dc-a:2,metro-dc-b:1

    .. seealso::
        :ref:`cluster/databases/placement`

    .. config:option:: seedlist

    An optional, comma-delimited list of node names that this node should
    contact in order to join a cluster. If a seedlist is configured the ``_up``
    endpoint will return a 404 until the node has successfully contacted at
    least one of the members of the seedlist and replicated an up-to-date copy
    of the ``_nodes``, ``_dbs``, and ``_users`` system databases.

        [cluster]
        seedlist = couchdb@node1.example.com,couchdb@node2.example.com
