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

.. _api/db/_partition:

Ordinarily, the documents inside a database are arbitrarily assigned
into a shard range. This has an adverse affect on query performance as
it is necessary to contact every shard range to answer each query (it
is not possible to know, a priori, which shard ranges have no
matches).

A partitioned database (created with ``?partitioned=true``) provides a
solution to this if your use case is suitable. All documents within a
partitioned database have a special format for their document id's

.. code-block:: text

    partition:id

Where both ``partition`` and ``id`` adhere to the CouchDB document id
restrictions.

Documents with the same ``partition`` value are placed in the same shard
range as each other. You should choose your ``partition`` values with
care, the scalability and performance of this feature critically
depends on it; ideally you have a natural choice in your application
(user name or account name, for example) that partitions your data
such that each partition can be queried meaningfully.

==============================
``/db/_partition/{partition}``
==============================

.. http:get:: /{db}/_partition/{partition}

    Returns information about the specified partition.

    **Request**:

    .. code-block:: http

        GET /db/_partition/foo HTTP/1.1
        Host: localhost:5984

    **Response**:

    .. code-block:: http

        HTTP/1.1 200 OK
        Content-Type: application/json
        Server: CouchDB (Erlang/OTP)

        {
            "ok": true,
            "db_name": "db",
            "partition_name": "foo",
            "doc_count": 10,
            "doc_del_count": 2,
            "sizes": {
                "active": 235,
                "external": 412
            }
        }

==================================
``/db/_partition/partition/_find``
==================================

.. http:post:: /{db}/_partition/{partition}/_find
    :synopsis: Find documents inside a specific partition

    Find documents inside a specific partition, see the main
    documentation for :ref:`_find <api/db/_find>`.

    :param db: Database name
    :param partition: Partition name
