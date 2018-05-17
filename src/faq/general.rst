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

.. _faq/general:

General
=======

What is CouchDB?
----------------

CouchDB is a document-oriented, NoSQL_ database. The
:ref:`Introduction <intro>` provides a high level overview of the
CouchDB system.

.. _NoSQL: https://en.wikipedia.org/wiki/NoSQL

What does "Couch" mean?
-----------------------

"Couch" is an acronym which stands for **C**\ luster **O**\ f **U**\ nreliable
**C**\ ommodity **H**\ ardware. This is a statement of Couch's long-term goal of
massive scalability and high reliability on fault-prone hardware. The
distributed nature and flat address space of the database will enable node
partitioning for storage scalability (with a map/reduce style query facility)
and clustering for reliability and fault tolerance.

What language is CouchDB written in?
------------------------------------

Erlang_, a concurrent, functional programming language with an emphasis on fault
tolerance. Early work on CouchDB was started in C++ but was replaced by Erlang
OTP platform. Erlang has so far proven an excellent match for this project.

CouchDB's default view server uses Mozilla's SpiderMonkey_ JavaScript engine
which is written in C. It also supports easy integration of view servers
written in any language.

.. _Erlang: https://www.erlang.org/
.. _SpiderMonkey: https://developer.mozilla.org/en-US/docs/Mozilla/Projects/SpiderMonkey

What is the license?
--------------------

`Apache 2.0 <http://www.apache.org/licenses/LICENSE-2.0.html>`_
