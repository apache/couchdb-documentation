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
