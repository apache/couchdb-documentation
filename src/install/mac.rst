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

.. _install/mac:

========================
Installation on Mac OS X
========================

.. _install/mac/binary:

Installation using the Apache CouchDB native application
========================================================

The easiest way to run CouchDB on Mac OS X is through the native Mac OS X
application. Just follow the below instructions:

#. `Download Apache CouchDB for Mac OS X`_.
   Old releases are available at `archive`_.
#. Double click on the Zip file
#. Drag and drop the Apache CouchDB.app into Applications folder

.. _Download Apache CouchDB for Mac OS X: http://couchdb.org/#download
.. _archive: http://archive.apache.org/dist/couchdb/binary/mac/

That's all, now CouchDB is installed on your Mac:

#. Run Apache CouchDB application
#. `Open up Fauxton`_, the CouchDB admin interface
#. Verify the install by clicking on `Verify`, then `Verify Installation`.
#. Time to Relax!

.. _Open up Fauxton: http://localhost:5984/_utils

.. _install/mac/homebrew:

Installation with Homebrew
==========================

The `Homebrew`_ build of CouchDB 2.0 is still in development. Check back often
for updates.

.. _Homebrew: http://brew.sh/

Running as a Daemon
-------------------

CouchDB no longer ships with any daemonization scripts.

You can use the `launchctl` command to control the CouchDB daemon.

The couchdb team recommends `runit <http://smarden.org/runit/>`_ to
run CouchDB persistently and reliably. Configuration of runit is
straightforward; if you have questions, reach out to the CouchDB
user mailing list.

Naturally, you can configure launchd or other init daemons to
launch CouchDB and keep it running using standard configuration files.

Consult your system documentation for more information.
