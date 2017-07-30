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

.. _install/setup:

================
First-Time Setup
================

CouchDB 2.0 can be used in a single-node or clustered configuration.
Below are the first-time setup steps required for each of these
configurations.

.. _install/setup/single:

Single Node Setup
=================

A single node CouchDB 2.0 installation is what most users will be using.
It is roughly equivalent to the CouchDB 1.x-series. Note that a
single-node setup obviously doesn't take any advantage of the new
scaling and fault-tolerance features in CouchDB 2.0.

After installation and initial startup, visit Fauxton at
``http://127.0.0.1:5984/_utils#setup``. You will be asked to set up
CouchDB as a single-node instance or set up a cluster. When you click
“Single-Node-Setup”, you will get asked for an admin username and
password. Choose them well and remember them. You can also bind CouchDB
to a public address, so it is accessible within your LAN or the public, if
you are doing this on a public VM. Or, you can keep the installation private
by binding only to 127.0.0.1 (localhost). The wizard then configures your admin
username and password and creates the three system databases ``_users``,
``_replicator`` and ``_global_changes`` for you.

Alternatively, if you don't want to use the “Single-Node-Setup” wizard
and run 2.0 as a single node with admin username and password already
configured, make sure to create the three three system databases manually
on startup:

.. code-block:: sh

    curl -X PUT http://127.0.0.1:5984/_users

    curl -X PUT http://127.0.0.1:5984/_replicator

    curl -X PUT http://127.0.0.1:5984/_global_changes

Note that the last of these is not necessary if you do not expect to be
using the global changes feed. Feel free to delete this database if you
have created it, it has grown in size, and you do not need the function
(and do not wish to waste system resources on compacting it regularly.)

See the next section for the cluster setup instructions.

.. _install/setup/cluster:

Cluster Setup
=============

As configuration has many steps, see the :ref:`Cluster Reference Setup
<cluster/setup>` for full details.
