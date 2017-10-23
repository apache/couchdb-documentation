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

.. highlight:: ini

==========
Replicator
==========

.. _config/replicator:

Replicator Database Configuration
=================================

.. config:section:: replicator :: Replicator Database Configuration

    .. config:option:: max_jobs

        .. versionadded:: 2.1

        Number of actively running replications. Making this too high could
        cause performance issues. Making it too low could mean replications
        jobs might not have enough time to make progress before getting
        unscheduled again. This parameter can be adjusted at runtime and will
        take effect during next rescheduling cycle::

             [replicator]
             max_jobs = 500

    .. config:option:: interval

        .. versionadded:: 2.1

        Scheduling interval in milliseconds. During each reschedule cycle
        scheduler might start or stop up to "max_churn" number of jobs::

             [replicator]
             interval = 60000

    .. config:option:: max_churn

        .. versionadded:: 2.1

        Maximum number of replications to start and stop during rescheduling.
        This parameter along with ``interval`` defines the rate of job
        replacement. During startup, however a much larger number of jobs could
        be started (up to ``max_jobs``) in a short period of time::

             [replicator]
             max_churn = 20

    .. config:option:: update_docs

        .. versionadded:: 2.1

        When set to ``true`` replicator will update replication document with
        error and triggered states. This approximates pre-2.1 replicator
        behavior::

             [replicator]
             update_docs = false

    .. config:option:: worker_batch_size

        With lower batch sizes checkpoints are done more frequently. Lower
        batch sizes also reduce the total amount of used RAM memory::

            [replicator]
            worker_batch_size = 500

    .. config:option:: worker_processes

        More worker processes can give higher network throughput but can also
        imply more disk and network IO::

            [replicator]
            worker_processes = 4

    .. config:option:: http_connections

        Maximum number of HTTP connections per replication::

            [replicator]
            http_connections = 20

    .. config:option:: connection_timeout

        HTTP connection timeout per replication.
        Even for very fast/reliable networks it might need to be increased if
        a remote database is too busy::

            [replicator]
            connection_timeout = 30000

    .. config:option:: retries_per_request

        .. versionchanged:: 2.1.1

        If a request fails, the replicator will retry it up to N times. The
        default value for N is 5 (before version 2.1.1 it was 10). The requests
        are retried with a doubling exponential backoff starting at 0.25
        seconds. So by default requests would be retried in 0.25, 0.5, 1, 2, 4
        second intervals. When number of retires is exhausted, the whole
        replication job is stopped and will retry again later::

            [replicator]
            retries_per_request = 5

    .. config:option:: socket_options

        Some socket options that might boost performance in some scenarios:

        - ``{nodelay, boolean()}``
        - ``{sndbuf, integer()}``
        - ``{recbuf, integer()}``
        - ``{priority, integer()}``

        See the `inet`_ Erlang module's man page for the full list of options::

            [replicator]
            socket_options = [{keepalive, true}, {nodelay, false}]

        .. _inet: http://www.erlang.org/doc/man/inet.html#setopts-2

    .. config:option:: checkpoint_interval

        .. versionadded:: 1.6

        Defines replication checkpoint interval in milliseconds.
        :ref:`Replicator <replicator>` will :get:`requests </{db}>` from the
        Source database at the specified interval::

            [replicator]
            checkpoint_interval = 5000

        Lower intervals may be useful for frequently changing data, while
        higher values will lower bandwidth and make fewer requests for
        infrequently updated databases.

    .. config:option:: use_checkpoints

        .. versionadded:: 1.6

        If ``use_checkpoints`` is set to ``true``, CouchDB will make
        checkpoints during replication and at the completion of replication.
        CouchDB can efficiently resume replication from any of these
        checkpoints::

            [replicator]
            use_checkpoints = true

        .. note::
            Checkpoints are stored in :ref:`local documents <api/local>`
            on both the source and target databases (which requires write
            access).

        .. warning::
            Disabling checkpoints is **not recommended** as CouchDB will scan
            the Source database's changes feed from the beginning.

    .. config:option:: cert_file

        Path to a file containing the user's certificate::

            [replicator]
            cert_file = /full/path/to/server_cert.pem

    .. config:option:: key_file

        Path to file containing user's private PEM encoded key::

            [replicator]
            key_file = /full/path/to/server_key.pem

    .. config:option:: password

        String containing the user's password. Only used if the private key file
        is password protected::

            [replicator]
            password = somepassword

    .. config:option:: verify_ssl_certificates

        Set to true to validate peer certificates::

            [replicator]
            verify_ssl_certificates = false

    .. config:option:: ssl_trusted_certificates_file

        File containing a list of peer trusted certificates (in the PEM
        format)::

            [replicator]
            ssl_trusted_certificates_file = /etc/ssl/certs/ca-certificates.crt

    .. config:option:: ssl_certificate_max_depth

        Maximum peer certificate depth (must be set even if certificate
        validation is off)::

            [replicator]
            ssl_certificate_max_depth = 3
