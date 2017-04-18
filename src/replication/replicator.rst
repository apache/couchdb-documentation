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

.. _replicator:

===================
Replicator Database
===================

The ``_replicator`` database works like any other in CouchDB, but documents
added to it will trigger replications. Create (``PUT`` or ``POST``) a document
to start replication. ``DELETE`` a replication document to cancel an ongoing
replication.

These documents have exactly the same content as the JSON objects we used to
``POST`` to ``_replicate`` (fields ``source``, ``target``, ``create_target``,
``continuous``, ``doc_ids``, ``filter``, ``query_params``, ``use_checkpoints``,
``checkpoint_interval``).

Replication documents can have a user defined ``_id`` (handy for finding a
specific replication request later). Design Documents (and ``_local`` documents)
added to the replicator database are ignored.

The default name of this database is ``_replicator``. Additional replicator
databases can be created. To be recognized as such by the system, their database
names should end with ``/_replicator``.

Basics
======

Let's say you POST the following document into ``_replicator``:

.. code-block:: javascript

    {
        "_id": "my_rep",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "create_target":  true
    }

In the couch log you'll see 2 entries like these:

.. code-block:: text

    [Thu, 17 Feb 2011 19:43:59 GMT] [info] [<0.291.0>] Document `my_rep` triggered replication `c0ebe9256695ff083347cbf95f93e280+create_target`
    [Thu, 17 Feb 2011 19:44:37 GMT] [info] [<0.124.0>] Replication `c0ebe9256695ff083347cbf95f93e280+create_target` finished (triggered by document `my_rep`)

As soon as the replication is triggered, the document will be updated by
CouchDB with 3 new fields:

.. code-block:: javascript

    {
        "_id": "my_rep",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "create_target":  true,
        "_replication_id":  "c0ebe9256695ff083347cbf95f93e280",
        "_replication_state":  "triggered",
        "_replication_state_time":  "2011-02-17T20:22:02+01:00"
    }

Special fields set by the replicator start with the prefix
``_replication_``.

- ``_replication_id``

  The ID internally assigned to the replication. This is also the ID
  exposed by ``/_active_tasks``.

- ``_replication_state``

  The current state of the replication.

- ``_replication_state_time``

  The time in RFC3339 format when the current replication state (marked in
  ``_replication_state``) was set.

- ``_replication_state_reason``

  If ``replication_state`` is ``error``, this field contains the reason.

.. code-block:: javascript

    {
        "_id": "my_rep",
        "_rev": "2-9f2c0d9372f4ee4dc75652ab8f8e7c70",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "_replication_state": "error",
        "_replication_state_time": "2013-12-13T18:48:00+01:00",
        "_replication_state_reason": "db_not_found: could not open foodb",
        "_replication_id": "c0ebe9256695ff083347cbf95f93e280"
    }

When the replication finishes, it will update the ``_replication_state``
field (and ``_replication_state_time``) with the value ``completed``, so
the document will look like:

.. code-block:: javascript

    {
        "_id": "my_rep",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "create_target":  true,
        "_replication_id":  "c0ebe9256695ff083347cbf95f93e280",
        "_replication_state":  "completed",
        "_replication_state_time":  "2011-02-17T20:22:02+01:00"
    }

When an error happens during replication, the ``_replication_state``
field is set to ``error`` (and ``_replication_state_reason`` and
``_replication_state_time`` are updated).

When you PUT/POST a document to the ``_replicator`` database, CouchDB
will attempt to start the replication up to 10 times (configurable under
``[replicator]``, parameter ``max_replication_retry_count``). If it
fails on the first attempt, it waits 5 seconds before doing a second
attempt. If the second attempt fails, it waits 10 seconds before doing a
third attempt. If the third attempt fails, it waits 20 seconds before
doing a fourth attempt (each attempt doubles the previous wait period).
When an attempt fails, the Couch log will show you something like:

.. code-block:: text

    [error] [<0.149.0>] Error starting replication `67c1bb92010e7abe35d7d629635f18b6+create_target` (document `my_rep_2`): {db_not_found,<<"could not open http://myserver:5986/foo/">>

.. note::
    The ``_replication_state`` field is only set to ``error`` when all the
    attempts were unsuccessful.

There are only 3 possible values for the ``_replication_state`` field:
``triggered``, ``completed`` and ``error``. Continuous replications
never get their state set to ``completed``.

Documents describing the same replication
=========================================

Lets suppose 2 documents are added to the ``_replicator`` database in
the following order:

.. code-block:: javascript

    {
        "_id": "doc_A",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar"
    }

and

.. code-block:: javascript

    {
        "_id": "doc_B",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar"
    }

Both describe exactly the same replication (only their ``_ids`` differ). In this
case document ``doc_A`` triggers the replication, getting updated by CouchDB
with the fields ``_replication_state``, ``_replication_state_time`` and
``_replication_id``, just like it was described before. Document ``doc_B``
however, is only updated with one field, the ``_replication_id`` so it will
look like this:

.. code-block:: javascript

    {
        "_id": "doc_B",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "_replication_id":  "c0ebe9256695ff083347cbf95f93e280"
    }

While document ``doc_A`` will look like this:

.. code-block:: javascript

    {
        "_id": "doc_A",
        "source":  "http://myserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "_replication_id":  "c0ebe9256695ff083347cbf95f93e280",
        "_replication_state":  "triggered",
        "_replication_state_time":  "2011-02-17T20:22:02+01:00"
    }

Note that both document get exactly the same value for the ``_replication_id``
field. This way you can identify which documents refer to the same replication -
you can for example define a view which maps replication IDs to document IDs.

Canceling replications
======================

To cancel a replication simply ``DELETE`` the document which triggered the
replication. The Couch log will show you an entry like the following:

.. code-block:: text

    [Thu, 17 Feb 2011 20:16:29 GMT] [info] [<0.125.0>] Stopped replication `c0ebe9256695ff083347cbf95f93e280+continuous+create_target` because replication document `doc_A` was deleted

.. note::
    You need to ``DELETE`` the document that triggered the replication.
    ``DELETE``-ing another document that describes the same replication
    but did not trigger it, will not cancel the replication.

Server restart
==============

When CouchDB is restarted, it checks its ``_replicator`` database and
restarts any replication that is described by a document that either has
its ``_replication_state`` field set to ``triggered`` or it doesn't have
yet the ``_replication_state`` field set.

.. note::
    Continuous replications always have a ``_replication_state`` field
    with the value ``triggered``, therefore they're always restarted
    when CouchDB is restarted.

Updating Documents in the Replicator Database
=============================================

Once the replicator has started work on a job defined in the ``_replicator``
database, modifying the replication document is no longer allowed. Attempting
to do this will result in the following response

.. code-block:: javascript

    {
        "error": "forbidden",
        "reason": "Only the replicator can edit replication documents that are in the triggered state."
    }

The way to accomplish this is to first delete the old version and then insert
the new one.

Additional Replicator Databases
===============================

Imagine replicator database (``_replicator``) has these two
documents which represent pull replications from servers A and B:

.. code-block:: javascript

    {
        "_id": "rep_from_A",
        "source":  "http://aserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/foo_a",
        "continuous":  true,
        "_replication_id":  "c0ebe9256695ff083347cbf95f93e280",
        "_replication_state":  "triggered",
        "_replication_state_time":  "2011-02-17T19:35:11+01:00"
    }

.. code-block:: javascript

    {
        "_id": "rep_from_B",
        "source":  "http://bserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/foo_b",
        "continuous":  true,
        "_replication_id":  "231bb3cf9d48314eaa8d48a9170570d1",
        "_replication_state":  "triggered",
        "_replication_state_time":  "2011-02-17T20:22:02+01:00"
    }

Now without stopping and restarting CouchDB, add another replicator database.
For example ``another/_replicator``:

.. code-block:: bash

    $ curl -X PUT http://user:pass@localhost:5984/another%2F_replicator/
    {"ok":true}

.. note::
   A / character in a database name, when used in a URL, should be escaped.

Then add a replication document to the new replicator database:

.. code-block:: javascript

    {
        "_id": "rep_from_X",
        "source":  "http://xserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/foo_x",
        "continuous":  true
    }

From now on, there are three replications active in the system: two replications
from A and B, and a new one from X.

Then remove the additional replicator database:

.. code-block:: bash

    $ curl -X DELETE http://user:pass@localhost:5984/another%2F_replicator/
    {"ok":true}

After this operation, replication pulling from server X
will be stopped and the replications in the ``_replicator``
database (pulling from servers A and B) will continue.

Replicating the replicator database
===================================

Imagine you have in server C a replicator database with the two
following pull replication documents in it:

.. code-block:: javascript

    {
         "_id": "rep_from_A",
         "source":  "http://aserver.com:5984/foo",
         "target":  "http://user:pass@localhost:5984/foo_a",
         "continuous":  true,
         "_replication_id":  "c0ebe9256695ff083347cbf95f93e280",
         "_replication_state":  "triggered",
         "_replication_state_time":  "2011-02-17T19:35:11+01:00"
    }

.. code-block:: javascript

    {
         "_id": "rep_from_B",
         "source":  "http://bserver.com:5984/foo",
         "target":  "http://user:pass@localhost:5984/foo_b",
         "continuous":  true,
         "_replication_id":  "231bb3cf9d48314eaa8d48a9170570d1",
         "_replication_state":  "triggered",
         "_replication_state_time":  "2011-02-17T20:22:02+01:00"
    }

Now you would like to have the same pull replications going on in server
D, that is, you would like to have server D pull replicating from
servers A and B. You have two options:

- Explicitly add two documents to server's D replicator database

- Replicate server's C replicator database into server's D replicator
  database

Both alternatives accomplish exactly the same goal.

Delegations
===========

Replication documents can have a custom ``user_ctx`` property. This
property defines the user context under which a replication runs. For
the old way of triggering a replication (POSTing to ``/_replicate/``),
this property is not needed. That's because information about the
authenticated user is readily available during the replication, which is
not persistent in that case. Now, with the replicator database, the
problem is that information about which user is starting a particular
replication is only present when the replication document is written.
The information in the replication document and the replication itself
are persistent, however. This implementation detail implies that in the
case of a non-admin user, a ``user_ctx`` property containing the user's
name and a subset of their roles must be defined in the replication
document. This is enforced by the document update validation function
present in the default design document of the replicator database. The
validation function also ensures that non-admin users are unable to set
the value of the user context's ``name`` property to anything other than
their own user name. The same principle applies for roles.

For admins, the ``user_ctx`` property is optional, and if it's missing
it defaults to a user context with name ``null`` and an empty list of
roles, which means design documents won't be written to local targets.
If writing design documents to local targets is desired, the role
``_admin`` must be present in the user context's list of roles.

Also, for admins the ``user_ctx`` property can be used to trigger a
replication on behalf of another user. This is the user context that
will be passed to local target database document validation functions.

.. note::
    The ``user_ctx`` property only has effect for local endpoints.

Example delegated replication document:

.. code-block:: javascript

    {
        "_id": "my_rep",
        "source":  "http://bserver.com:5984/foo",
        "target":  "http://user:pass@localhost:5984/bar",
        "continuous":  true,
        "user_ctx": {
            "name": "joe",
            "roles": ["erlanger", "researcher"]
        }
    }

As stated before, the ``user_ctx`` property is optional for admins, while
being mandatory for regular (non-admin) users. When the roles property
of ``user_ctx`` is missing, it defaults to the empty list ``[]``.

.. _selectorobj:

Selector Objects
================

Including a Selector Object in the replication document enables you to
use a query expression to determine if a document should be included in
the replication.

The selector specifies fields in the document, and provides an expression
to evaluate with the field content or other data. If the expression resolves
to ``true``, the document is replicated.

The selector object must:

-  Be structured as valid JSON.
-  Contain a valid query expression.

The syntax for a selector is the same as the
:ref:`selectorsyntax <find/selectors>` used for :ref:`_find <api/db/_find>`.

Using a selector is significantly more efficient than using a JavaScript
filter function, and is the recommended option if filtering on document
attributes only.
