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

.. _install/docker:

=======================
Installation via Docker
=======================

Apache CouchDB provides 'convenience binary' Docker images through
Docker Hub at ``apache/couchdb``. The following tags are available:

* ``latest``, ``2``, ``2.3``, ``2.3.1``: CouchDB 2.3.1, single node
* ``1``, ``1.7``, ``1.7.2``: CouchDB 1.7.2
* ``1-couchperuser``, ``1.7-couchperuser``, ``1.7.2-couchperuser``: CouchDB
  1.7.2 with couchperuser plugin
* ``2.3.0``: CouchDB 2.3.0, single node

These images are built using Debian 9 (stretch), expose CouchDB on port
``5984`` of the container, run everything as user ``couchdb``, and support
use of a Docker volume for data at ``/opt/couchdb/data``.

Note that you can also use the ``NODENAME`` environment variable to set the
name of the CouchDB node inside the container.

**Your installation is not complete. Be sure to complete the**
:ref:`Setup <setup>` **steps for a single node or clustered installation.**

Further details on the Docker configuration are available in our
`couchdb-docker git repository`_.

.. _couchdb-docker git repository: https://github.com/apache/couchdb-docker
