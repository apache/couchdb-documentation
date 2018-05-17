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

.. _faq/troubleshooting:

===============
Troubleshooting
===============

Where are the CouchDB log files located?
----------------------------------------

For a default Linux/Unix installation the log files are located here::

    /usr/local/var/log/couchdb/couch.log

This is set in the default.ini file located here::

    /etc/couchdb/default.ini

If you've installed from source and are running CouchDB in dev mode the log
files are located here::

    YOUR-COUCHDB-SOURCE-DIRECTORY/tmp/log/couch.log

How do I use transactions with CouchDB?
---------------------------------------

CouchDB uses an "optimistic concurrency" model. In the simplest terms, this
just means that you send a document version along with your update, and CouchDB
rejects the change if the current document version doesn't match what you've
sent.

It's deceptively simple, really. You can reframe many normal transaction based
scenarios for CouchDB. You do need to sort of throw out your RDBMS domain
knowledge when learning CouchDB, though. It's helpful to approach problems from
a higher level, rather than attempting to mold Couch to a SQL based world.

**Keeping track of inventory**

The problem you outlined is primarily an inventory issue. If you have a document
describing an item, and it includes a field for "quantity available", you can
handle concurrency issues like this:

- Retrieve the document, take note of the `_rev` property that CouchDB sends
  along
- Decrement the quantity field, if it's greater than zero
- Send the updated document back, using the `_rev` property
- If the `_rev` matches the currently stored number, be done!
- If there's a conflict (when `_rev` doesn't match), retrieve the newest
  document version

In this instance, there are two possible failure scenarios to think about. If
the most recent document version has a quantity of 0, you handle it just like
you would in a RDBMS and alert the user that they can't actually buy what they
wanted to purchase. If the most recent document version has a quantity greater
than 0, you simply repeat the operation with the updated data, and start back
at the beginning. This forces you to do a bit more work than an RDBMS would, and
could get a little annoying if there are frequent, conflicting updates.

Now, the answer I just gave presupposes that you're going to do things in
CouchDB in much the same way that you would in an RDBMS. I might approach this
problem a bit differently:

I'd start with a "master product" document that includes all the descriptor data
(name, picture, description, price, etc). Then I'd add an "inventory ticket"
document for each specific instance, with fields for product_key and claimed_by.
If you're selling a model of hammer, and have 20 of them to sell, you might have
documents with keys like hammer-1, hammer-2, etc, to represent each available
hammer.

Then, I'd create a view that gives me a list of available hammers, with a reduce
function that lets me see a "total". These are completely off the cuff, but
should give you an idea of what a working view would look like.

**Map**::

    function(doc)
    {
        if (doc.type == 'inventory_ticket' && doc.claimed_by == null ) {
            emit(doc.product_key, { 'inventory_ticket' :doc.id, '_rev' : doc._rev });
        }
    }

This gives me a list of available "tickets", by product key. I could grab a
group of these when someone wants to buy a hammer, then iterate through sending
updates (using the id and _rev) until I successfully claim one (previously
claimed tickets will result in an update error).

**Reduce**::

    function (keys, values, combine) {
        return values.length;
    }

This reduce function simply returns the total number of unclaimed
inventory_ticket items, so you can tell how many "hammers" are available for
purchase.

**Caveats**

This solution represents roughly 3.5 minutes of total thinking for the
particular problem you've presented. There may be better ways of doing this!
That said, it does substantially reduce conflicting updates, and cuts down on
the need to respond to a conflict with a new update. Under this model, you won't
have multiple users attempting to change data in primary product entry. At the
very worst, you'll have multiple users attempting to claim a single ticket, and
if you've grabbed several of those from your view, you simply move on to the
next ticket and try again.

.. note::
    This FAQ entry was borrowed from
    http://stackoverflow.com/questions/299723/can-i-do-transactions-and-locks-in-couchdb
    with permission from the author

Why does creating my view take so long?
---------------------------------------

There are a number of possible reasons:

1. Your reduce function is not reducing the input data to a small enough output.
See Introduction_to_CouchDB_views#reduce_functions for more details.

2. If you have a lot of documents or lots of large documents (going into the
millions and Gigabytes), the first time a view index is created just takes the
time it is needed to run through all documents.

3. If you use the emit()-function in your view with doc as the second parameter
you effectively copy your entire data into the view index. This takes a lot of
time. Consider rewriting your emit() call to emit(key, null); and query the view
with the `?include_docs=true parameter` to get all doc's data with the view
without having to copy the data into the view index.

How can I "JOIN" with CouchDB?
------------------------------

See https://www.cmlenz.net/archives/2007/10/couchdb-joins

Why is my database so large, even after compaction?
---------------------------------------------------

Often, CouchDB users expect that adding a document to a database, then deleting
that document will return the database to its original state. However, this is
not the case. Consider a two-database scenario:

- Doc 1 inserted to DB A.
- DB A replicated to DB B.
- Doc 1 deleted from DB A.
- DB A replicated to DB B.

If inserting and then deleting a document returned the database to the original
state, the second replication from A to B would be "empty" and hence DB B would
be unchanged, which means it would be out of sync with DB A.

To handle this case, CouchDB keeps a record of each document deleted, by keeping
the document _id, _rev and _deleted=true. The data size per deleted doc depends
on the number of revisions that CouchDB has to track plus the data size for any
data stored in the deleted revision (this is usually relatively small, kilobytes
perhaps, but varies based on use case). It is possible to keep audit trail data
with a deleted document (ie. application-specific things like "deleted_by" and
"deleted_at"). While generally this is not an issue, if the DB is still larger
than expected, even after considering the minimum size of a deleted document,
check to insure that the deleted document doesn't contain data not unintended
for keeping past the deletion action. Specifically, if your client library is
not careful, it could be storing a full copy of each document in the deleted
revisions. For more information:
https://issues.apache.org/jira/browse/COUCHDB-1141

My database will require an unbounded number of deletes, what can I do?
-----------------------------------------------------------------------

If there's a strong correlation between time (or some other regular
monotonically increasing event) and document deletion, a DB setup can be used
like the following:

- Assume that the past 30 days of logs are needed, anything older can be
  deleted.
- Set up DB logs_2011_08.
- Replicate logs_2011_08 to logs_2011_09, filtered on logs from 2011_08 only.
- During August, read/write to logs_2011_08.
- When September starts, create logs_2011_10.
- Replicate logs_2011_09 to logs_2011_10, filtered on logs from 2011_09 only.
- During September, read/write to logs_2011_09.
- Logs from August will be present in logs_2011_09 due to the replication, but
  not in logs_2011_10.
- The entire logs_2011_08 DB can be removed.
- Frequently_asked_questions (last edited 2013-06-13 12:47:31 by 50)

Why are logged errors are often so confusing?
---------------------------------------------
While the Erlang messages in the log can be confusing to someone unfamiliar with
Erlang, with practice they become very helpful. The CouchDB developers do try
to catch and log messages that might be useful to a system administrator in a
friendly format, but occasionally a bug or otherwise unexpected behavior
manifests itself in more verbose dumps of Erlang server state. These messages
can be very useful to CouchDB developers. If you find many confusing messages in
your log, feel free to inquire about them. If they are expected, devs can work
to ensure that the message is more cleanly formatted. Otherwise, the messages
may indicate a bug in the code.

In many cases, this is enough to identify the problem. For example, OS errors
are reported as tagged tuples ``{error,enospc}`` or ``{error,enoacces}`` which
respectively is "You ran out of disk space", and "CouchDB doesn't have
permission to access that resource". Most of these errors are derived from C
used to build the Erlang VM and are documented in errno.h and related header
files. `IBM <https://www.ibm.com/developerworks/aix/library/au-errnovariable/>`_
provides a good introduction to these, and the relevant
`POSIX
<http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/errno.h.html>`_,
GNU_,
and  `Microsoft Windows <https://msdn.microsoft.com/en-us/library/5814770t.aspx>`_
standards will cover most cases.

.. _GNU: http://www.gnu.org/savannah-checkouts/gnu/libc/manual/html_node/Error-Codes.html
