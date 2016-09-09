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
uses ``5986`` for node-local APIs.

Erlang uses TCP port ``4369`` (EPMD) to find other nodes, so all servers must be
able to speak to each other on this port. In an Erlang Cluster, all nodes are
connected to all other nodes. A mesh.

.. warning::
    If you expose the port ``4369`` to the Internet or any other untrusted
    network, then the only thing protecting you is the
    `cookie`_.

.. _cookie: http://erlang.org/doc/reference_manual/distributed.html

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

.. _cluster/setup/wizard:

The Cluster Setup Wizard
========================

Setting up a cluster of Erlang applications correctly can be a daunting
task. Luckily, CouchDB 2.0 comes with a convenient Cluster Setup Wizard
as part of the Fauxton web administration interface.

After installation and initial startup, visit Fauxton at
``http://127.0.0.01:5984/_utils#setup``. You will be asked to set up
CouchDB as a single-node instance or set up a cluster.

When you click "setup cluster" on the other hand, you are asked for
admin credentials again and then to add nodes by IP address. To get
more nodes, go through the same install procedure on other machines.

Before you can add nodes to form a cluster, you have to have them
listen on a public ip address and set up an admin user. Do this, once
per node:

.. code-block:: bash

    curl -X PUT http://127.0.0.1:5984/_node/couchdb@<this-nodes-ip-address>/_config/admins/admin -d '"password"'
    curl -X PUT http://127.0.0.1:5984/_node/couchdb@<this-nodes-ip-address>/_config/chttpd/bind_address -d '"0.0.0.0"'

Now you can enter their IP addresses in the setup screen on your first
node. And make sure to put in the admin username and password. And use
the same admin username and password on all nodes.

Once you added all nodes, click "Setup" and Fauxton will finish the
cluster configuration for you.

See http://127.0.0.1:5984/_membership to get a list of all the nodes in
your cluster.

Now your cluster is ready and available. You can send requests to any
one of the nodes and get to all the data.

For a proper production setup, you'd now set up a HTTP proxy in front
of the nodes, that does load balancing. We recommend `HAProxy`_. See
our `example configuration for HAProxy`_. All you need is to adjust the
ip addresses and ports.

.. _HAProxy: http://haproxy.org/
.. _example configuration for HAProxy: https://github.com/apache/couchdb/blob/master/rel/haproxy.cfg
