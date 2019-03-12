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

.. _best-practices/reverse-proxies:

========================
Reverse Proxies
========================

Reverse proxying with HAProxy
=============================

CouchDB recommends the use of `HAProxy`_ as a load balancer and reverse proxy.
The team's experience with using it in production has shown it to be superior
for configuration and montioring capabilities, as well as overall performance.

CouchDB's sample haproxy configuration is present in the `code repository`_ and
release tarball as ``rel/haproxy.cfg``. It is included below. This example
is for a 3 node CouchDB cluster:

.. code-block:: text

    global
        maxconn 512
        spread-checks 5

    defaults
        mode http
        log global
        monitor-uri /_haproxy_health_check
        option log-health-checks
        option httplog
        balance roundrobin
        option forwardfor
        option redispatch
        retries 4
        option http-server-close
        timeout client 150000
        timeout server 3600000
        timeout connect 500

        stats enable
        stats uri /_haproxy_stats
        # stats auth admin:admin # Uncomment for basic auth

    frontend http-in
         # This requires HAProxy 1.5.x
         # bind *:$HAPROXY_PORT
         bind *:5984
         default_backend couchdbs

    backend couchdbs
        option httpchk GET /_up
        http-check disable-on-404
        server couchdb1 x.x.x.x:5984 check inter 5s
        server couchdb2 x.x.x.x:5984 check inter 5s
        server couchdb2 x.x.x.x:5984 check inter 5s

.. _HAProxy: http://haproxy.org/
.. _code repository: https://github.com/apache/couchdb/blob/master/rel/haproxy.cfg

Reverse proxying with nginx
===========================

Basic Configuration
-------------------

Here's a basic excerpt from an nginx config file in
``<nginx config directory>/sites-available/default``. This will proxy all
requests from ``http://domain.com/...`` to ``http://localhost:5984/...``

.. code-block:: text

    location / {
        proxy_pass http://localhost:5984;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

Proxy buffering **must** be disabled, or continuous replication will not
function correctly behind nginx.

Reverse proxying CouchDB in a subdirectory with nginx
-----------------------------------------------------

It can be useful to provide CouchDB as a subdirectory of your overall domain,
especially to avoid CORS concerns. Here's an excerpt of a basic nginx
configuration that proxies the URL ``http://domain.com/couchdb`` to
``http://localhost:5984`` so that requests appended to the subdirectory, such
as ``http://domain.com/couchdb/db1/doc1`` are proxied to
``http://localhost:5984/db1/doc1``.

.. code-block:: text

    location /couchdb {
        rewrite /couchdb/(.*) /$1 break;
        proxy_pass http://localhost:5984;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

To enable session based replication with reverse proxied CouchDB in a subdirectory.

.. code-block:: text

    location /_session {
        proxy_pass http://localhost:5984/_session;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

Authentication with nginx as a reverse proxy
--------------------------------------------

Here's a sample config setting with basic authentication enabled, placing
CouchDB in the ``/couchdb`` subdirectory:

.. code-block:: text

    location /couchdb {
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
        rewrite /couchdb/(.*) /$1 break;
        proxy_pass http://localhost:5984;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Authorization "";
    }

This setup leans entirely on nginx performing authorization, and forwarding
requests to CouchDB with no authentication (with CouchDB in Admin Party mode).
For a better solution, see :ref:`api/auth/proxy`.

SSL with nginx
--------------------------------------------

In order to enable SSL, just enable the nginx SSL module, and add another
proxy header:

.. code-block:: text

    ssl on;
    ssl_certificate PATH_TO_YOUR_PUBLIC_KEY.pem;
    ssl_certificate_key PATH_TO_YOUR_PRIVATE_KEY.key;
    ssl_protocols SSLv3;
    ssl_session_cache shared:SSL:1m;

    location / {
        proxy_pass http://localhost:5984;
        proxy_redirect off;
        proxy_set_header Host $host;
        proxy_buffering off;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Ssl on;
    }

The ``X-Forwarded-Ssl`` header tells CouchDB that it should use the ``https``
scheme instead of the ``http`` scheme. Otherwise, all CouchDB-generated
redirects will fail.

Reverse Proxying with Caddy
===========================

Basic configuration
-------------------

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
-----------------------------------------------------

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

Reverse proxying + load balancing for CouchDB clusters
------------------------------------------------------

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
            keepalive 0
            transparent
        }

    }

Authentication with Caddy as a reverse proxy
--------------------------------------------

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
------------------

Caddy is https-by-default, and will automatically acquire, install, activate and,
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

Reverse Proxying with Apache HTTP Server
========================================

.. warning::
    As of this writing, there is no way to fully disable the buffering between
    Apache HTTPD Server and CouchDB. This may present problems with continuous
    replication. The Apache CouchDB team strongly recommend the use of an
    alternative reverse proxy such as ``haproxy`` or ``nginx``, as described
    earlier in this section.

Basic Configuration
-------------------

Here's a basic excerpt for using a ``VirtualHost`` block config to use Apache
as a reverse proxy for CouchDB. You need at least to configure Apache with the
``--enable-proxy --enable-proxy-http`` options and use a version equal to or
higher than Apache 2.2.7 in order to use the ``nocanon`` option in the
``ProxyPass`` directive. The ``ProxyPass`` directive adds the ``X-Forwarded-For``
header needed by CouchDB, and the ``ProxyPreserveHost`` directive ensures the
original client ``Host`` header is preserved.

.. code-block:: apacheconf

    <VirtualHost *:80>
       ServerAdmin webmaster@dummy-host.example.com
       DocumentRoot "/opt/websites/web/www/dummy"
       ServerName couchdb.localhost
       AllowEncodedSlashes On
       ProxyRequests Off
       KeepAlive Off
       <Proxy *>
          Order deny,allow
          Deny from all
          Allow from 127.0.0.1
       </Proxy>
       ProxyPass / http://localhost:5984 nocanon
       ProxyPassReverse / http://localhost:5984
       ProxyPreserveHost On
       ErrorLog "logs/couchdb.localhost-error_log"
       CustomLog "logs/couchdb.localhost-access_log" common
    </VirtualHost>
