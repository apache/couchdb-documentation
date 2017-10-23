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

.. _replication/intro:

===========================
Introduction to Replication
===========================

One of CouchDB's strengths is the ability to synchronize two copies of the same
database. This enables users to distribute data across several nodes or
data centers, but also to move data more closely to clients.

Replication involves a source and a destination database, which can be on the
same or on different CouchDB instances. The aim of the replication is that at
the end of the process, all active documents on the source database are also in
the destination database and all documents that were deleted in the source
databases are also deleted on the destination database (if they even existed).

Triggering Replication
======================

Replication is controlled through documents in the
:ref:`_replicator <replicator>` database, where each document describes one
replication process (see :ref:`replication-settings`).

A replication is triggered by storing a replication document in the replicator
database. Its status can be inspected through the active tasks API (see
:ref:`api/server/active_tasks` and :ref:`replication-status`). A replication can
be stopped by deleting the document, or by updating it with its `cancel`
property set to `true`.

Replication Procedure
=====================

During replication, CouchDB will compare the source and the destination
database to determine which documents differ between the source and the
destination database. It does so by following the :ref:`changes` on the source
and comparing the documents to the destination. Changes are submitted to the
destination in batches where they can introduce conflicts. Documents that
already exist on the destination in the same revision are not transferred. As
the deletion of documents is represented by a new revision, a document deleted
on the source will also be deleted on the target.

A replication task will finish once it reaches the end of the changes feed. If
its `continuous` property is set to true, it will wait for new changes to
appear until the task is canceled. Replication tasks also create checkpoint
documents on the destination to ensure that a restarted task can continue from
where it stopped, for example after it has crashed.

When a replication task is initiated on the sending node, it is called *push*
replication, if it is initiated by the receiving node, it is called *pull*
replication.

Master - Master replication
===========================

One replication task will only transfer changes in one direction. To achieve
master-master replication, it is possible to set up two replication tasks in
opposite direction. When a change is replicated from database A to B by the
first task, the second task from B to A will discover that the new change on
B already exists in A and will wait for further changes.

Controlling which Documents to Replicate
========================================

There are three options for controlling which documents are replicated,
and which are skipped:

1. Defining documents as being local.
2. Using :ref:`selectorobj`.
3. Using :ref:`filterfun`.

Local documents are never replicated (see :ref:`api/local`).

:ref:`selectorobj` can be included in a replication document (see
:ref:`replication-settings`). A selector object contains a query expression
that is used to test whether a document should be replicated.

:ref:`filterfun` can be used in a replication (see
:ref:`replication-settings`). The replication task evaluates
the filter function for each document in the changes feed. The document is
only replicated if the filter returns `true`.

.. note::
    Using a selector provides performance benefits when compared with using a
    :ref:`filterfun`. You should use :ref:`selectorobj` where possible.

.. note::
    When using replication filters that depend on the document's content,
    deleted documents may pose a problem, since the document passed to the
    filter will not contain any of the document's content. This can be
    resolved by adding a ``_deleted:true`` field to the document instead
    of using the DELETE HTTP method, paired with the use of a
    :ref:`validate document update <vdufun>` handler to ensure the fields
    required for replication filters are always present. Take note, though,
    that the deleted document will still contain all of its data (including
    attachments)!

Migrating Data to Clients
=========================

Replication can be especially useful for bringing data closer to clients.
`PouchDB <http://pouchdb.com/>`_ implements the replication algorithm of CouchDB
in JavaScript, making it possible to make data from a CouchDB database
available in an offline browser application, and synchronize changes back to
CouchDB.
