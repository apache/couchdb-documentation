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

.. _best-practices/nginx:

========================
nginx as a Reverse Proxy
========================

CouchDB recommends the use of `HAProxy`_ as a load balancer and reverse proxy.
The team's experience with using it in production has shown it to be superior
for configuration and montioring capabilities, as well as overall performance.

CouchDB's sample haproxy configuration is present in the `code repository`_ and
release tarball as ``rel/haproxy.cfg``.

However, ``nginx`` is a suitable alternative. Below are instructions on
configuring nginx appropriately.

.. _HAProxy: http://haproxy.org/
.. _code repository: https://github.com/apache/couchdb/blob/master/rel/haproxy.cfg

Basic configuration
===================

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
=====================================================

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

Note that in the above configuration, the *Verify Installation* link in
Fauxton may not succeed.

Authentication with nginx as a reverse proxy
============================================

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
==============

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
