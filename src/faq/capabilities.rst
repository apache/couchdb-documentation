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

.. _faq/capabilities:

============
Capabilities
============

What platforms are supported?
-----------------------------

- Most POSIX systems, including GNU/Linux, OS X and FreeBSD.
- Windows is officially supported.

How much stuff can I store in CouchDB?
--------------------------------------

The database size is primarily limited by resource limitations of your hardware
and operating system. with node partitioning, this can be increased drastically,
to be virtually unlimited.

Can I talk to CouchDB without going through the HTTP API?
---------------------------------------------------------

CouchDB's data model and internal API map the REST/HTTP model so well that any
other API would basically reinvent some flavor of HTTP. However, there is a
plan to refactor CouchDB's internals so as to provide a documented Erlang API.

Is Unicode or UTF-8 a problem with CouchDB?
-------------------------------------------

CouchDB uses Erlang binaries internally. All data coming to CouchDB must be
UTF-8 encoded.

Can views update documents or databases?
----------------------------------------

No. Views are always read-only to databases and their documents.
