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

.. _install/upgrading:

==========================
Upgrading from CouchDB 1.x
==========================

CouchDB 2.x fully supports upgrading from CouchDB 1.x. A data migration
process is required to use CouchDB 1.x databases in CouchDB 2.x. CouchDB
2.1 supplies a utility, ``couchup``, to simplify the migration process.

``couchup`` utility
===================

The ``couchup`` utility is a Python script that supports listing CouchDB
1.x databases on a CouchDB 2.x installation, migrating them for use with
CouchDB 2.x, rebuilding any database views after migration, and deleting
the 1.x databases once migration is complete.

``couchup`` runs under Python 2.7 or 3.x, and requires the Python
`requests library <http://python-requests.org/>`_, and can optionally
make use of the Python `progressbar library
<https://pypi.python.org/pypi/progressbar>`_.

Overview
--------

couchup makes it easy to migrate your CouchDB 1.x databases to CouchDB
2.x by providing useful 4 sub-commands:

* ``list`` - lists all CouchDB 1.x databases
* ``replicate`` - replicates one or more 1.x databases to CouchDB 2.x
* ``rebuild`` - rebuilds one or more CouchDB 2.x views
* ``delete`` - deletes one or more CouchDB 1.x databases

Once you have installed CouchDB 2.x, copy the .couch files from
your 1.x installation (or, if you've upgraded in-place, do nothing),
then use commands similar to the following:

.. code-block:: bash

    $ couchup list           # Shows your unmigrated 1.x databases
    $ couchup replicate -a   # Replicates your 1.x DBs to 2.x
    $ couchup rebuild -a     # Optional; starts rebuilding your views
    $ couchup delete -a      # Deletes your 1.x DBs (careful!)
    $ couchup list           # Should show no remaining databases!

The same process works for moving from a single 1.x node to a cluster of
2.x nodes; the only difference is that you must complete cluster setup
prior to running the couchup commands.

Special Features
----------------

* Lots of extra help is available via:

.. code-block:: bash

    $ couchup -h
    $ couchup <sub-command> -h

* Various optional arguments provide for admin login/password,
  overriding ports, quiet mode and so on.

* ``couchup delete`` will NOT delete your 1.x DBs unless the contents are
  identical to the replicated 2.x DBs, or you override with the
  ``-f/--force`` command (be VERY careful with this!!)

* ``couchup replicate`` supports an optional flag, ``-f/--filter-deleted``, to
  filter delete documents during the replication process. This can
  improve the performance and disk-size of your database if it has a lot
  of deleted documents.

  It is IMPORTANT that no documents be deleted
  from the 1.x database during this process, or those deletions may not
  successfully replicate to the 2.x database. (It's recommended that
  you not access or modify the 1.x database at all during the whole
  ``couchup`` process.)

Manual CouchDB 1.x migration
============================

If you cannot use the ``couchup`` utility, or prefer to migrate
yourself, a manual migration is also possible. In this process, a
full-featured HTTP client such as ``curl`` is required.

The process is similar to the automated approach:

1. Copy all of your 1.x .couch files to the CouchDB 2.x ``data/``
   directory and start CouchDB (2.x).
2. Set up replication for each database from the node-local port
   (default: 5986) to the clustered port (default: 5984). This can be
   done via the :ref:`/_replicate <api/server/replicate>` endpoint or
   the :ref:`replicator database <replicator>`.
3. Rebuild each view by accessing it through the clustered port.
4. Confirm that all databases and views can be accessed as desired.
5. Remove the 1.x databases via a ``DELETE`` request on the
   **node-local** port (default: 5986).
