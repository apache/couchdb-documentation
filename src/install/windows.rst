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

.. _install/windows:

=======================
Installation on Windows
=======================

There are two ways to install CouchDB on Windows.

Installation from binaries
==========================

This is the simplest way to go.

#. Get `the latest Windows binaries`_ from `CouchDB web site`_.
   Old releases are available at `archive`_.

#. Follow the installation wizard steps:

   - Next on "Welcome" screen
   - Accept the License agreement
   - Select the installation directory
   - Specify "Start Menu" group name
   - Approve that you'd like to install CouchDB as service and let it be
     started automatically after installation (probably, you'd like so)
   - Verify installation settings
   - Install CouchDB

#. `Open up Fauxton`_ (if you hadn't selected autostart CouchDB after
   installation, you have to start it first manually)

#. It's time to Relax!

.. note::
    In some cases you might been asked to reboot Windows to complete
    installation process, because of using on different Microsoft Visual C++
    runtimes by CouchDB.

.. note::
    **Upgrading note**

    It's recommended to uninstall previous CouchDB version before upgrading,
    especially if the new one is built against different Erlang release.
    The reason is simple: there may be leftover libraries with alternative or
    incompatible versions from old Erlang release that may create conflicts,
    errors and weird crashes.

    In this case, make sure you backup of your `local.ini` config and CouchDB
    database/index files.

.. _Open up Fauxton: http://localhost:5984/_utils
.. _CouchDB web site: http://couchdb.org/
.. _archive: http://archive.apache.org/dist/couchdb/binary/win/
.. _the latest Windows binaries: http://couchdb.org/#download

Installation from sources
=========================

.. seealso::
    `Glazier: Automate building of CouchDB from source on Windows
    <https://git1-us-west.apache.org/repos/asf?p=couchdb-glazier.git;a=tree>`_
