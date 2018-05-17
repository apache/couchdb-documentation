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

.. _faq/howto:

=======
How-Tos
=======

How can I use auto-increment sequences?
---------------------------------------

With replication, sequences are hard to realize. Sequences are often used to
ensure unique identifiers for each row in a database table. CouchDB generates
unique ids on its own and you can specify your own as well, so you don't really
need a sequence here. If you use a sequence for something else, you might find
a way to express it in CouchDB in another way.

How can I get a list of the design documents in a database?
-----------------------------------------------------------

Query the `_all_docs` view with `startkey="_design/"&endkey="_design0"`.
