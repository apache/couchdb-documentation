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

.. _install/snap:

=====================
Installation via Snap
=====================

.. highlight:: sh

Apache CouchDB provides 'convenience binary' Snap builds through the
Ubuntu snapcraft repository under the name ``couchdb``. Only snaps built
from official stable CouchDB releases (``2.0``, ``2.1``, etc.) are available
through this channel.

After `installing snapd`_, the couchdb snap can be installed via::

    $ sudo snap install couchdb

CouchDB will be installed at ``/snap/couchdb``. Data will be stored at
``/var/snap/couchdb/``.

.. _installing snapd: https://snapcraft.io/docs/core/install

Further details on the snap build process are available in our
`couchdb-pkg git repository`_.

.. _couchdb-pkg git repository: https://github.com/apache/couchdb-pkg
