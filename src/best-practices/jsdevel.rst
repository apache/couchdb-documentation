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

.. _best-practices/jsdevel:

===========================
JavaScript development tips
===========================

Working with Apache CouchDB's JavaScript environment is a lot different than
working with traditional JavaScript development environments. Here are some
tips and tricks that will ease the difficulty.

.. rst-class:: open

- Remember that CouchDB's JavaScript engine is old, only supporting the
  ECMA-262 5th edition ("ES5") of the language. ES6/2015 and newer constructs
  cannot be used.

- The ``log()`` function will log output to the CouchDB log file or stream.
  You can log strings, objects, and arrays directly, without first converting
  to JSON.  Use this in conjunction with a local CouchDB instance for best
  results.

- Be sure to guard all document accesses to avoid exceptions when fields
  or subfields are missing: ``if (doc && doc.myarray && doc.myarray.length)...``
