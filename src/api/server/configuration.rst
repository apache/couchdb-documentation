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

.. _api/config:

=============
Configuration
=============

The classical CouchDB Server Configuration API located at ``/_config`` will
return a 404 in CouchDB 2.0 and got replaced by :ref:`HTTP API <api/node>`.

For 2.0 we recommend using a configuration management tools like Chef, Ansible,
Puppet or Salt (in no particular order) to configure your nodes in a cluster.

You can read the configuration of every node in a cluster using
:ref:`HTTP API <api/node>`.

For a "cluster of one", a cluster with just one node, it is also considered
save to use :ref:`HTTP API <api/node>` for setting new configuration values.
