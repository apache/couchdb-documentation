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

.. _cluster:

==================
Cluster Management
==================

As of CouchDB 2.0.0, CouchDB can be run in two different modes of operation:
    * Standalone: The default mode of operation. Each instance is a single logical entity. Typically replication is setup to other standalone CouchDB instances.
    * Cluster: Multiple CouchDBs build a single entity where each CouchDB is a node in the cluster. The cluster itsself is a single logical database which is hosted on multiple servers/VMs. Operations like writing need to reach a quorum in the cluster to guarantee that the change is agreed on by all nodes eventually.

This section details the theory behind CouchDB clusters, and provides specific
operational instructions on node, database and shard management.

.. toctree::
    :maxdepth: 2

    theory
    nodes
    databases
    sharding
    purging
