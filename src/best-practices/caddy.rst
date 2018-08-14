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

.. _best-practices/Caddy:

========================
Caddy as a Reverse Proxy
========================

CouchDB recommends the use of `HAProxy`_ as a load balancer and reverse proxy.
The team's experience with using it in production has shown it to be superior
for configuration and monitoring capabilities, as well as overall performance.

CouchDB's sample haproxy configuration is present in the `code repository`_ and
release tarball as ``rel/haproxy.cfg``.

However, ``Caddy`` is a suitable alternative. Below are instructions on
configuring Caddy appropriately.

.. _HAProxy: http://haproxy.org/
.. _code repository: https://github.com/apache/couchdb/blob/master/rel/haproxy.cfg

Basic configuration
===================

Here's a basic excerpt from a Caddyfile in
``/<path>/<to>/<site>/Caddyfile``. This will proxy all
requests from ``http(s)://domain.com/...`` to ``http://localhost:5984/...``

.. code-block:: text

    domain.com {

        import /path/to/other/config.caddy # logging, error handling etc.

        proxy / localhost:5984 {
            transparent
        }

    }

.. Note::
    The ``transparent`` preset in the ``proxy`` directive is shorthand for:

    .. code-block:: text

        header_upstream Host {host}
        header_upstream X-Real-IP {remote}
        header_upstream X-Forwarded-For {remote}
        header_upstream X-Forwarded-Proto {scheme}

Note that, because Caddy is https-by-default, you must explicitly include the
``http://`` protocol in the site address if you do NOT want Caddy
to automatically acquire and install an SSL certificate and begin accepting
``https`` connections on port 443.

Reverse proxying CouchDB in a subdirectory with Caddy
=====================================================

It can be useful to provide CouchDB as a subdirectory of your overall domain,
especially to avoid CORS concerns. Here's an excerpt of a basic Caddy
configuration that proxies the URL ``http(s)://domain.com/couchdb`` to
``http://localhost:5984`` so that requests appended to the subdirectory, such
as ``http(s)://domain.com/couchdb/db1/doc1`` are proxied to
``http://localhost:5984/db1/doc1``.

.. code-block:: text

    domain.com {

        import /path/to/other/config.caddy # logging, error handling etc.

        proxy /couchdb localhost:5984 {
            transparent
            without /couchdb
        }

    }

Note that in the above configuration, the *Verify Installation* link in
Fauxton may not succeed.

Reverse proxying + load balancing for CouchDB clusters
======================================================

Here's a basic excerpt from a Caddyfile in
``/<path>/<to>/<site>/Caddyfile``. This will proxy and evenly distribute all
requests from ``http(s)://domain.com/...`` among 3 CouchDB cluster nodes
at ``localhost:15984``, ``localhost:25984`` and ``localhost:35984``.

Caddy will check the status, i.e. health, of each node every 5 seconds;
if a node goes down, Caddy will avoid proxying requests to that node until it
comes back online.

.. code-block:: text

    domain.com {

        import /path/to/other/config.caddy # logging, error handling etc.

        proxy / http://localhost:15984 http://localhost:25984 http://localhost:35984 {
            policy round_robin
            health_check /_up
            health_check_duration 5s
            try_interval 500ms
            timeout 1h
            transparent
        }

    }

Note that in the above configuration, the *Verify Installation* link in
Fauxton may not succeed.

Authentication with Caddy as a reverse proxy
============================================

Here's a sample config setting with basic authentication enabled, placing
CouchDB in the ``/couchdb`` subdirectory:

.. code-block:: text

    domain.com {

        import /path/to/other/config.caddy # logging, error handling etc.

        basicauth /couchdb couch_username couchdb_password

        proxy /couchdb localhost:5984 {
            transparent
            header_upstream -Authorization
            without /couchdb
        }

    }

For security reasons, using a plaintext password in the ``Caddyfile`` is not
advisable. One solution is to define Caddy-process environment variables e.g.
``COUCH_PW=couchdb_password`` and using placeholders in the ``Caddyfile``
instead, e.g. ``{$COUCH_PW}``.

This setup leans entirely on Caddy performing authorization, and forwarding
requests to CouchDB with no authentication (with CouchDB in Admin Party mode).
For a better solution, see :ref:`api/auth/proxy`.

SSL/TLS with Caddy
==================

Caddy is http-by-default, and will automatically acquire, install, activate and,
when necessary, renew a trusted SSL certificate for you - all in the background.
Certificates are issued by the LetsEncrypt certificate authority.

.. code-block:: text

    domain.com {

        import /path/to/other/config.caddy # logging, error handling etc.

        proxy / localhost:5984 {
            transparent
            header_upstream x-forwarded-ssl on
        }

    }

The ``x-forwarded-ssl`` header tells CouchDB that it should use the ``https``
scheme instead of the ``http`` scheme. Otherwise, all CouchDB-generated
redirects will fail.
