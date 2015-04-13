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

.. _cluster/setup:

=====
Setup
=====

Everything you need to know to prepare the cluster for the installation of
CouchDB.

Firewall
========

If you do not have a firewall between your servers, then you can skip this.

CouchDB in cluster mode uses the port ``5984`` just as standalone, but is also
uses ``5986`` for the admin interface.

Erlang uses TCP port ``4369`` (EPMD) to find other nodes, so all servers must be
able to speak to each other on this port. In an Erlang Cluster, all nodes are
connected to all other nodes. A mesh.

.. warning::
    If you expose the port ``4369`` to the Internet or any other untrusted
    network, then the only thing protecting you is the
    :ref:`cookie <cluster/setup/cookie>`.

Every Erlang application then uses other ports for talking to each other. Yes,
this means random ports. This will obviously not work with a firewall, but it is
possible to force an Erlang application to use a specific port rage.

This documentation will use the range TCP ``9100-9200``. Open up those ports in
your firewalls and it is time to test it.

You need 2 servers with working hostnames. Let us call them server1 and server2.

On server1:

.. code-block:: bash

    erl -sname bus -setcookie 'brumbrum' -kernel inet_dist_listen_min 9100 -kernel inet_dist_listen_max 9200

Then on server2:

.. code-block:: bash

    erl -sname car -setcookie 'brumbrum' -kernel inet_dist_listen_min 9100 -kernel inet_dist_listen_max 9200

An explanation to the commands:
    * ``erl`` the Erlang shell.
    * ``-sname bus`` the name of the Erlang node.
    * ``-setcookie 'brumbrum'`` the "password" used when nodes connect to each
      other.
    * ``-kernel inet_dist_listen_min 9100`` the lowest port in the rage.
    * ``-kernel inet_dist_listen_max 9200`` the highest port in the rage.

This gives us 2 Erlang shells. shell1 on server1, shell2 on server2.
Time to connect them. The ``.`` is to Erlang what ``;`` is to C.

In shell1:

.. code-block:: erlang

    net_kernel:connect_node(car@server2).

This will connect to the node called ``car`` on the server called ``server2``.

If that returns true, then you have a Erlang cluster, and the firewalls are
open. If you get false or nothing at all, then you have a problem with the
firewall.

First time in Erlang? Time to play!
-----------------------------------

Run in both shells:

.. code-block:: erlang

    register(shell, self()).

shell1:

.. code-block:: erlang

    {shell, car@server2} ! {hello, from, self()}.

shell2:

.. code-block:: erlang

    flush().
    {shell, bus@server1} ! {"It speaks!", from, self()}.

shell1:

.. code-block:: erlang

    flush().

To close the shells, run in both:

.. code-block:: erlang

    q().

Make CouchDB use the open ports.
--------------------------------

Open ``sys.config``, on all nodes, and add ``inet_dist_listen_min, 9100`` and
``inet_dist_listen_max, 9200`` like below:

.. code-block:: erlang

    [
        {lager, [
            {error_logger_hwm, 1000},
            {error_logger_redirect, true},
            {handlers, [
                {lager_console_backend, [debug, {
                    lager_default_formatter,
                    [
                        date, " ", time,
                        " [", severity, "] ",
                        node, " ", pid, " ",
                        message,
                        "\n"
                    ]
                }]}
            ]},
            {inet_dist_listen_min, 9100},
            {inet_dist_listen_max, 9200}
        ]}
    ].

Configuration files
===================

.. _cluster/setup/cookie:

Erlang Cookie
-------------

Open up ``vm.args`` and set the ``-setcookie`` to something secret. This must be
identical on all nodes.

Set ``-name`` to the name the node will have. All nodes must have a unique name.

Admin
-----

All nodes authenticates users locally, so you must add an admin user to
local.ini on all nodes. Otherwise you will not be able to login on the cluster.
