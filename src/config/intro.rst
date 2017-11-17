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

.. default-domain:: config
.. _config/intro:

===========================
Introduction To Configuring
===========================

Configuration files
===================

By default, CouchDB reads configuration files from the following locations,
in the following order:

#. ``etc/default.ini``
#. ``etc/default.d/*.ini``
#. ``etc/local.ini``
#. ``etc/local.d/*.ini``

All paths are specified relative to the CouchDB installation directory:
``/opt/couchdb`` recommended on UNIX-like systems, ``C:\CouchDB`` recommended
on Windows systems, and a combination of two directories on macOS:
``Applications/Apache CouchDB.app/Contents/Resources/couchdbx-core/etc`` for
the ``default.ini`` and ``default.d`` directories, and
``/Users/youruser/Library/Application Support/CouchDB2/etc/couchdb`` for
the ``local.ini`` and ``local.d`` directories.

Settings in successive documents override the settings in earlier entries.
For example, setting the :option:`httpd/bind_address` parameter in
``local.ini`` would override any setting in ``default.ini``.

.. warning::
    The ``default.ini`` file may be overwritten during an upgrade or
    re-installation, so localised changes should be made to the ``local.ini``
    file or files within the ``local.d`` directory.

.. highlight:: sh

The configuration file chain may be changed by setting the ERL_FLAGS
environment variable::

    export ERL_FLAGS="-couch_ini /path/to/my/default.ini /path/to/my/local.ini"

or by placing the ``-couch_ini ..`` flag directly in the ``etc/vm.args`` file.
Passing ``-couch_ini ..`` as a command-line argument when launching ``couchdb``
is the same as setting the ``ERL_FLAGS`` environment variable.

.. warning::
    The environment variable/command-line flag overrides any ``-couch_ini``
    option specified in the ``etc/vm.args`` file. And, **BOTH** of these
    options **completely** override CouchDB from searching in the default
    locations. Use these options only when necessary, and be sure to track
    the contents of ``etc/default.ini``, which may change in future releases.

Parameter names and values
==========================

All parameter names are *case-sensitive*. Every parameter takes a value of one
of five types: `boolean`, `integer`, `string`, `tuple`_ and `proplist`_.
Boolean values can be written as ``true`` or ``false``.

Parameters with value type of `tuple` or `proplist` are following the Erlang
requirement for style and naming.

.. _proplist: http://www.erlang.org/doc/man/proplists.html
.. _tuple: http://www.erlang.org/doc/reference_manual/data_types.html#id66049

Setting parameters via the configuration file
=============================================

The common way to set some parameters is to edit the ``local.ini`` file
(location explained above).

.. highlight:: ini

For example::

    ; This is a comment
    [section]
    param = value ; inline comments are allowed

Each configuration file line may contains `section` definition, `parameter`
specification, empty (space and newline characters only) or `commented` line.
You can set up `inline` commentaries for `sections` or `parameters`.

The `section` defines group of parameters that are belongs to some specific
CouchDB subsystem. For instance, :section:`httpd` section holds not only HTTP
server parameters, but also others that directly interacts with it.

The `parameter` specification contains two parts divided by the `equal` sign
(``=``): the parameter name on the left side and the parameter value on the
right one. The leading and following whitespace for ``=`` is an optional to
improve configuration readability.

.. note::
    In case when you'd like to remove some parameter from the `default.ini`
    without modifying that file, you may override in `local.ini`, but without
    any value::

        [httpd_global_handlers]
        _all_dbs =

    This could be read as: "remove the `_all_dbs` parameter from the
    `httpd_global_handlers` section if it was ever set before".

The semicolon (``;``) signals the start of a comment. Everything after this
character is ignored by CouchDB.

After editing the configuration file, CouchDB should be restarted to apply
any changes.

Setting parameters via the HTTP API
===================================

.. highlight:: sh

Alternatively, configuration parameters can be set via the
:ref:`HTTP API <api/config>`. This API allows changing CouchDB configuration
on-the-fly without requiring a server restart::

    curl -X PUT http://localhost:5984/_node/<name@host>/_config/uuids/algorithm -d '"random"'

The old parameter's value is returned in the response::

    "sequential"

You should be careful changing configuration via the HTTP API since it's
possible  to make CouchDB unreachable, for example, by changing the
:option:`httpd/bind_address`::

    curl -X PUT http://localhost:5984/_node/<name@host>/_config/httpd/bind_address -d '"10.10.0.128"'

If you make a typo or the specified IP address is not available from your
network, CouchDB will be unreachable. The only way to resolve this will be
to remote into the server, correct the config file, and restart CouchDB. To
protect yourself against such accidents you may set the
:option:`httpd/config_whitelist` of permitted configuration parameters for
updates via the HTTP API. Once this option is set, further changes to
non-whitelisted parameters must take place via the configuration file, and in
most cases, will also require a server restart before taking effect.
