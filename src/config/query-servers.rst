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

=============
Query Servers
=============

.. _config/query_servers:

Query Servers Definition
========================

.. config:section:: query_servers :: Query Servers Definition

    .. versionchanged:: 1.2: Added CoffeeScript query server

    CouchDB delegates computation of :ref:`design documents <ddocs>` functions
    to external query servers. The external query server is a special OS
    process which communicates with CouchDB over standard input/output using a
    very simple line-based protocol with JSON messages.

    The external query server may be defined in configuration file following
    next pattern::

        [query_servers]
        LANGUAGE = PATH ARGS

    Where:

    - ``LANGUAGE``: is a programming language which code this query server may
      execute. For instance, there are `python`, `ruby`, `clojure` and other
      query servers in wild. This value is also used for `ddoc` field
      ``language`` to determine which query server processes the functions.

      Note, that you may set up multiple query servers for the same programming
      language, but you have to name them different (like `python-dev` etc.).

    - ``PATH``: is a system path to the executable binary program that runs the
      query server.

    - ``ARGS``: optionally, you may specify additional command line arguments
      for the executable ``PATH``.

    The default query server is written in :ref:`JavaScript <query-server/js>`,
    running via `Mozilla SpiderMonkey`_::

        [query_servers]
        javascript = /usr/bin/couchjs /usr/share/couchdb/server/main.js
        coffeescript = /usr/bin/couchjs /usr/share/couchdb/server/main-coffee.js

    By default, ``couchjs`` limits the max runtime allocation to 64MiB.
    If you run into out of memory issue in your ddoc functions,
    you can adjust the memory limitation::

        [query_servers]
        javascript = /usr/bin/couchjs -S 536870912 /usr/share/couchdb/server/main.js ; 512 MiB

    For more info about the available options, please consult ``couchjs -h``.

    .. _Mozilla SpiderMonkey: https://developer.mozilla.org/en/docs/SpiderMonkey

    .. seealso::
        :ref:`Native Erlang Query Server <config/native_query_servers>` that
        allows to process Erlang `ddocs` and runs within CouchDB bypassing
        stdio communication and JSON serialization/deserialization round trip
        overhead.

.. _config/query_server_config:

Query Servers Configuration
===========================

.. config:section:: query_server_config :: Query Servers Configuration

    .. config:option:: commit_freq :: View index commit delay

        Specifies the delay in seconds before view index changes are committed
        to disk. The default value is ``5``::

            [query_server_config]
            commit_freq = 5

    .. config:option:: os_process_limit :: Query Server process hard
                       limit

        Hard limit on the number of OS processes usable by Query
        Servers. The default value is ``100``::

            [query_server_config]
            os_process_limit = 100

        Setting `os_process_limit` too low can result in starvation of
        Query Servers, and manifest in `os_process_timeout` errors,
        while setting it too high can potentially use too many system
        resources. Production settings are typically 10-20 times the
        default value.

    .. config:option:: os_process_soft_limit :: Query Server process
                       soft limit

        Soft limit on the number of OS processes usable by Query
        Servers. The default value is ``100``::

            [query_server_config]
            os_process_soft_limit = 100

        Idle OS processes are closed until the total reaches the soft
        limit.

        For example, if the hard limit is 200 and the soft limit is
        100, the total number of OS processes will never exceed 200,
        and CouchDB will close all idle OS processes until it reaches
        100, at which point it will leave the rest intact, even if
        some are idle.

    .. config:option:: reduce_limit :: Reduce limit control

        Controls `Reduce overflow` error that raises when output of
        :ref:`reduce functions <reducefun>` is too big::

            [query_server_config]
            reduce_limit = true

        Normally, you don't have to disable (by setting ``false`` value) this
        option since main propose of `reduce` functions is to *reduce* the
        input.

.. _config/native_query_servers:

Native Erlang Query Server
==========================

.. config:section:: native_query_servers :: Native Erlang Query Server

    .. warning::
        Due to security restrictions, the Erlang query server is disabled by
        default.

        Unlike the JavaScript query server, the Erlang one does not runs in a
        sandbox mode. This means that Erlang code has full access to your OS,
        file system and network, which may lead to security issues. While Erlang
        functions are faster than JavaScript ones, you need to be careful
        about running them, especially if they were written by someone else.

    CouchDB has a native Erlang query server, allowing you to write your
    map/reduce functions in Erlang.

    First, you'll need to edit your `local.ini` to include a
    ``[native_query_servers]`` section::

        [native_query_servers]
        erlang = {couch_native_process, start_link, []}

    To see these changes you will also need to restart the server.

    Let's try an example of map/reduce functions which count the total
    documents at each number of revisions (there are x many documents at
    version "1", and y documents at "2"... etc). Add a few documents to the
    database, then enter the following functions as a view:

    .. code-block:: erlang

        %% Map Function
        fun({Doc}) ->
            <<K,_/binary>> = proplists:get_value(<<"_rev">>, Doc, null),
            V = proplists:get_value(<<"_id">>, Doc, null),
            Emit(<<K>>, V)
        end.

        %% Reduce Function
        fun(Keys, Values, ReReduce) -> length(Values) end.

    If all has gone well, after running the view you should see a list of the
    total number of documents at each revision number.
