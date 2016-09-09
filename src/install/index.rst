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

.. _install:

============
Installation
============

.. toctree::
    :maxdepth: 2

    unix
    windows
    mac
    freebsd
    troubleshooting

.. _install/cluster:

Single Node Setup
=================

CouchDB 2.0 can be used in a single-node and cluster setup
configuration. A single-node CouchDB 2.0 installation is what most
users will be using. It is roughly equivalent to the CouchDB
1.x-series. Note that a single-node setup obviously doesn't take any
advantage of the new scaling and fault-tolerance features in CouchDB
2.0.

After installation and initial startup, visit Fauxton at
``http://127.0.0.01:5984/_utils#setup``. You will be asked to set up
CouchDB as a single-node instance or set up a cluster.

When you click “Single-Node-Setup”, you will get asked for an admin
username and password. Choose them well and remember them. You can also
bind CouchDB to a public port, so it is accessible within your LAN or
the public, if you are doing this on a public VM.

When you run 2.0 as a single node, it doesn't create system databases
on startup. You have to do this manually:

.. code-block:: shell

    curl -X PUT http://127.0.0.1:5984/_users

    curl -X PUT http://127.0.0.1:5984/_replicator

    curl -X PUT http://127.0.0.1:5984/_global_changes

See the next section for the cluster setup instructions.

Cluster Setup
=============

See the :ref:`Cluster Reference <cluster>` for details.
