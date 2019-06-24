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

.. _api/ddoc/view:

==========================================
``/db/_design/design-doc/_view/view-name``
==========================================

.. http:get:: /{db}/_design/{ddoc}/_view/{view}
    :synopsis: Returns results for the specified stored view

    Executes the specified view function from the specified design document.

    :param db: Database name
    :param ddoc: Design document name
    :param view: View function name

    :<header Accept: - :mimetype:`application/json`
                     - :mimetype:`text/plain`

    :query boolean conflicts: Include `conflicts` information in response.
      Ignored if `include_docs` isn't ``true``. Default is ``false``.
    :query boolean descending: Return the documents in descending order by key.
      Default is ``false``.
    :query json endkey: Stop returning records when the specified key is
      reached.
    :query json end_key: Alias for `endkey` param
    :query string endkey_docid: Stop returning records when the specified
      document ID is reached. Ignored if `endkey` is not set.
    :query string end_key_doc_id: Alias for `endkey_docid`.
    :query boolean group: Group the results using the reduce function to a
      group or single row. Implies `reduce` is ``true`` and the maximum
      `group_level`. Default is ``false``.
    :query number group_level: Specify the group level to be used. Implies
      `group` is ``true``.
    :query boolean include_docs: Include the associated document with each row.
      Default is ``false``.
    :query boolean attachments: Include the Base64-encoded content of
      :ref:`attachments <api/doc/attachments>` in the documents that are
      included if `include_docs` is ``true``. Ignored if `include_docs` isn't
      ``true``. Default is ``false``.
    :query boolean att_encoding_info: Include encoding information in
      attachment stubs if `include_docs` is ``true`` and the particular
      attachment is compressed. Ignored if `include_docs` isn't ``true``.
      Default is ``false``.
    :query boolean inclusive_end: Specifies whether the specified end key
      should be included in the result. Default is ``true``.
    :query json key: Return only documents that match the specified key.
    :query json-array keys: Return only documents where the key matches one of
      the keys specified in the array.
    :query number limit: Limit the number of the returned documents to the
      specified number.
    :query boolean reduce: Use the reduction function. Default is ``true`` when
      a reduce function is defined.
    :query number skip: Skip this number of records before starting to return
      the results. Default is ``0``.
    :query boolean sorted: Sort returned rows (see :ref:`Sorting Returned Rows
     <api/ddoc/view/sorting>`). Setting this to ``false`` offers a performance
     boost. The `total_rows` and `offset` fields are not available when this
     is set to ``false``. Default is ``true``.
    :query boolean stable: Whether or not the view results should be returned
     from a stable set of shards. Default is ``false``.
    :query string stale: Allow the results from a stale view to be used.
      Supported values: ``ok``, ``update_after`` and ``false``.
      ``ok`` is equivalent to ``stable=true&update=false``.
      ``update_after`` is equivalent to ``stable=true&update=lazy``.
      ``false`` is equivalent to ``stable=false&update=true``.
    :query json startkey: Return records starting with the specified key.
    :query json start_key: Alias for `startkey`.
    :query string startkey_docid: Return records starting with the specified
      document ID. Ignored if ``startkey`` is not set.
    :query string start_key_doc_id: Alias for `startkey_docid` param
    :query string update: Whether or not the view in question should be updated
     prior to responding to the user. Supported values: ``true``, ``false``,
     ``lazy``. Default is ``true``.
    :query boolean update_seq: Whether to include in the response an
      `update_seq` value indicating the sequence id of the database the view
      reflects. Default is ``false``.

    :>header Content-Type: - :mimetype:`application/json`
                           - :mimetype:`text/plain; charset=utf-8`
    :>header ETag: Response signature
    :>header Transfer-Encoding: ``chunked``

    :>json number offset: Offset where the document list started.
    :>json array rows: Array of view row objects. By default the information
      returned contains only the document ID and revision.
    :>json number total_rows: Number of documents in the database/view.
    :>json object update_seq: Current update sequence for the database.

    :code 200: Request completed successfully
    :code 400: Invalid request
    :code 401: Read permission required
    :code 404: Specified database, design document or view is missed

    **Request**:

    .. code-block:: http

        GET /recipes/_design/ingredients/_view/by_name HTTP/1.1
        Accept: application/json
        Host: localhost:5984

    **Response**:

    .. code-block:: http

        HTTP/1.1 200 OK
        Cache-Control: must-revalidate
        Content-Type: application/json
        Date: Wed, 21 Aug 2013 09:12:06 GMT
        ETag: "2FOLSBSW4O6WB798XU4AQYA9B"
        Server: CouchDB (Erlang/OTP)
        Transfer-Encoding: chunked

        {
            "offset": 0,
            "rows": [
                {
                    "id": "SpaghettiWithMeatballs",
                    "key": "meatballs",
                    "value": 1
                },
                {
                    "id": "SpaghettiWithMeatballs",
                    "key": "spaghetti",
                    "value": 1
                },
                {
                    "id": "SpaghettiWithMeatballs",
                    "key": "tomato sauce",
                    "value": 1
                }
            ],
            "total_rows": 3
        }

.. versionchanged:: 1.6.0 added ``attachments`` and ``att_encoding_info``
    parameters
.. versionchanged:: 2.0.0 added ``sorted`` parameter
.. versionchanged:: 2.1.0 added ``stable`` and ``update`` parameters

.. warning::
    Using the ``attachments`` parameter to include attachments in view results
    is not recommended for large attachment sizes. Also note that the
    Base64-encoding that is used leads to a 33% overhead (i.e. one third) in
    transfer size for attachments.

.. http:post:: /{db}/_design/{ddoc}/_view/{view}
    :synopsis: Returns certain rows for the specified stored view

    Executes the specified view function from the specified design document.
    Unlike :get:`/{db}/_design/{ddoc}/_view/{view}` for accessing views, the
    :method:`POST` method supports the specification
    of explicit keys to be retrieved from the view results. The remainder of
    the :method:`POST` view functionality is identical to the
    :get:`/{db}/_design/{ddoc}/_view/{view}` API.

    **Request**:

    .. code-block:: http

        POST /recipes/_design/ingredients/_view/by_name HTTP/1.1
        Accept: application/json
        Content-Length: 37
        Host: localhost:5984

        {
            "keys": [
                "meatballs",
                "spaghetti"
            ]
        }

    **Response**:

    .. code-block:: http

        HTTP/1.1 200 OK
        Cache-Control: must-revalidate
        Content-Type: application/json
        Date: Wed, 21 Aug 2013 09:14:13 GMT
        ETag: "6R5NM8E872JIJF796VF7WI3FZ"
        Server: CouchDB (Erlang/OTP)
        Transfer-Encoding: chunked

        {
            "offset": 0,
            "rows": [
                {
                    "id": "SpaghettiWithMeatballs",
                    "key": "meatballs",
                    "value": 1
                },
                {
                    "id": "SpaghettiWithMeatballs",
                    "key": "spaghetti",
                    "value": 1
                }
            ],
            "total_rows": 3
        }

.. _api/ddoc/view/options:

View Options
============

There are two view indexing options that can be defined in a design document
as boolean properties of an ``options`` object. Unlike the others querying
options, these aren't URL parameters because they take effect when the view
index is generated, not when it's accessed:

- **local_seq** (*boolean*): Makes documents' local sequence numbers available
  to map functions (as a ``_local_seq`` document property)
- **include_design** (*boolean*): Allows map functions to be called on design
  documents as well as regular documents

.. _api/ddoc/view/indexing:

Querying Views and Indexes
==========================

The definition of a view within a design document also creates an index based
on the key information defined within each view. The production and use of the
index significantly increases the speed of access and searching or selecting
documents from the view.

However, the index is not updated when new documents are added or modified in
the database. Instead, the index is generated or updated, either when the view
is first accessed, or when the view is accessed after a document has been
updated. In each case, the index is updated before the view query is executed
against the database.

View indexes are updated incrementally in the following situations:

- A new document has been added to the database.
- A document has been deleted from the database.
- A document in the database has been updated.

View indexes are rebuilt entirely when the view definition changes. To achieve
this, a 'fingerprint' of the view definition is created when the design
document is updated. If the fingerprint changes, then the view indexes are
entirely rebuilt. This ensures that changes to the view definitions are
reflected in the view indexes.

.. note::
    View index rebuilds occur when one view from the same the view group (i.e.
    all the views defined within a single a design document) has been
    determined as needing a rebuild. For example, if if you have a design
    document with different views, and you update the database, all three view
    indexes within the design document will be updated.

Because the view is updated when it has been queried, it can result in a delay
in returned information when the view is accessed, especially if there are a
large number of documents in the database and the view index does not exist.
There are a number of ways to mitigate, but not completely eliminate, these
issues. These include:

- Create the view definition (and associated design documents) on your database
  before allowing insertion or updates to the documents. If this is allowed
  while the view is being accessed, the index can be updated incrementally.

- Manually force a view request from the database. You can do this either
  before users are allowed to use the view, or you can access the view manually
  after documents are added or updated.

- Use the :ref:`changes feed <api/db/changes>` to monitor for changes to the
  database and then access the view to force the corresponding view index to be
  updated.

None of these can completely eliminate the need for the indexes to be rebuilt
or updated when the view is accessed, but they may lessen the effects on
end-users of the index update affecting the user experience.

Another alternative is to allow users to access a 'stale' version of the view
index, rather than forcing the index to be updated and displaying the updated
results. Using a stale view may not return the latest information, but will
return the results of the view query using an existing version of the index.

For example, to access the existing stale view ``by_recipe`` in the
``recipes`` design document:

.. code-block:: text

    http://localhost:5984/recipes/_design/recipes/_view/by_recipe?stale=ok

Accessing a stale view:

- Does not trigger a rebuild of the view indexes, even if there have been
  changes since the last access.

- Returns the current version of the view index, if a current version exists.

- Returns an empty result set if the given view index does exist.

As an alternative, you use the ``update_after`` value to the ``stale``
parameter. This causes the view to be returned as a stale view, but for the
update process to be triggered after the view information has been returned to
the client.

In addition to using stale views, you can also make use of the ``update_seq``
query argument. Using this query argument generates the view information
including the update sequence of the database from which the view was
generated. The returned value can be compared this to the current update
sequence exposed in the database information (returned by :get:`/{db}`).

Search
======

Search indexes enable you to query a database by using
`Lucene Query Parser Syntax <http://lucene.apache.org/core/4_3_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#Overview>`_.
A search index uses one, or multiple, fields from your documents.
You can use a search index to run queries, find documents based on
the content they contain, or work with groups, facets, or
geographical searches.

.. warning::
    Search cannot function unless it has a functioning, cluster-connected
    Clouseau instance.

To create a search index, you add a JavaScript function to a design document
in the database. An index builds after processing one search request or after
the server detects a document update. The ``index`` function takes the
following parameters:

1.  Field name - The name of the field you want to use when you query the index.
If you set this parameter to ``default``, then this field is queried if no field
is specified in the query syntax.
2.  Data that you want to index, for example, ``doc.address.country``.
3.  (Optional) The third parameter includes the following fields: ``boost``, ``facet``,
``index``, and ``store``. These fields are described in more detail later.

By default, a search index response returns 25 rows. The number of rows that is
returned can be changed by using the ``limit`` parameter. However, a result set
from a search is limited to 200 rows. Each response includes a ``bookmark`` field.
You can include the value of the ``bookmark`` field in later queries to look
through the responses.

*Example design document that defines a search index:*

.. code-block:: javascript

    {
        "_id": "_design/search_example",
        "indexes": {
            "animals": {
                "index": "function(doc){ ... }"
            }
        }
    }

Search index partitioning type
------------------------------

A search index will inherit the partitioning type from the
``options.partitioned`` field of the design document that contains it.

Index functions
---------------

Attempting to index by using a data field that does not exist fails. To avoid
this problem, use the appropriate :ref:`index_guard_clauses <api/ddoc/view>`.

.. note::
    Your indexing functions operate in a memory-constrained environment
    where the document itself forms a part of the memory that is used
    in that environment. Your code's stack and document must fit inside this
    memory. In other words, a document must be loaded in order to be indexed.
    Documents are limited to a maximum size of 64 MB.

.. note::
    Within a search index, do not index the same field name with more than one data
    type. If the same field name is indexed with different data types in the same search
    index function, you might get an error when querying the search index that says the
    field "was indexed without position data." For example, do not include both of these
    lines in the same search index function, as they index the ``myfield`` field as two
    different data types: a string ``"this is a string"`` and a number ``123``.

.. code-block:: javascript

    index("myfield", "this is a string");
    index("myfield", 123);

The function that is contained in the index field is a JavaScript function
that is called for each document in the database.
The function takes the document as a parameter,
extracts some data from it, and then calls the function that is defined
in the ``index`` field to index that data.

The ``index`` function takes three parameters, where the third parameter is optional.

The first parameter is the name of the field you intend to use when querying the index,
and which is specified in the Lucene syntax portion of subsequent queries.
An example appears in the following query:

.. code-block:: javascript

    query=color:red

The Lucene field name ``color`` is the first parameter of the ``index`` function.

The ``query`` parameter can be abbreviated to ``q``,
so another way of writing the query is as follows:

.. code-block:: javascript

    q=color:red

If the special value ``"default"`` is used when you define the name,
you do not have to specify a field name at query time.
The effect is that the query can be simplified:

.. code-block:: javascript

    query=red

The second parameter is the data to be indexed. Keep the following information
in mind when you index your data:

- This data must be only a string, number, or boolean. Other types will cause
  an error to be thrown by the index function call.

- If an error is thrown when running your function, for this reason or others,
  the document will not be added to that search index.

The third, optional, parameter is a JavaScript object with the following fields:

*Index function (optional parameter)*

+-------------+-----------------------------------+----------------+-----------+
| Option      | Description                       | Values         | Default   |
+=============+===================================+================+===========+
|  ``boost``  | A number that specifies           | A positive     | 1 (no     |
|             | the relevance in                  | floating point | boosting) |
|             | search results. Content           | number         |           |
|             | that is indexed with a            |                |           |
|             | boost value greater               |                |           |
|             | than 1 is more relevant           |                |           |
|             | than content that is              |                |           |
|             | indexed without a boost           |                |           |
|             | value. Content with a             |                |           |
|             | boost value less than             |                |           |
|             | one is not so relevant.           |                |           |
+-------------+-----------------------------------+----------------+-----------+
| ``facet``   | Creates a faceted                 | ``true``,      | ``false`` |
|             | index. For more                   | ``false``      |           |
|             | information, see                  |                |           |
|             | :ref:`faceting <api/ddoc/view>`.  |                |           |
+-------------+-----------------------------------+----------------+-----------+
| ``index``   | Whether the data is indexed,      | ``true``,      | ``false`` |
|             | and if so, how. If set to         | ``false``      |           |
|             | ``false``, the data cannot        |                |           |
|             | be used for searches, but         |                |           |
|             | can still be retrieved            |                |           |
|             | from the index if ``store``       |                |           |
|             | is set to ``true``.  For more     |                |           |
|             | information, see                  |                |           |
|             | :ref:`analyzers <api/ddoc/view>`. |                |           |
+-------------+-----------------------------------+----------------+-----------+
| ``store``   | If ``true``, the value is         | ``true``,      | ``false`` |
|             | returned in the search result;    | ``false``      |           |
|             | otherwise, the value is           |                |           |
|             | not returned.                     |                |           |
+-------------+-----------------------------------+----------------+-----------+

.. note::

    If you do not set the ``store`` parameter,
    the index data results for the document are not returned in response to a query.

*Example search index function:*

.. code-block:: javascript

    function(doc) {
        index("default", doc._id);
        if (doc.min_length) {
            index("min_length", doc.min_length, {"store": true});
        }
        if (doc.diet) {
            index("diet", doc.diet, {"store": true});
        }
        if (doc.latin_name) {
            index("latin_name", doc.latin_name, {"store": true});
        }
        if (doc.class) {
            index("class", doc.class, {"store": true});
        }
    }

.. _api/ddoc/view/index_guard_clauses:

Index guard clauses
^^^^^^^^^^^^^^^^^^^

The ``index`` function requires the name of the data field to index as
the second parameter. However,
if that data field does not exist for the document,
an error occurs. The solution is to use an appropriate
'guard clause' that checks if the field exists,
and contains the expected type of data,
*before* any attempt to create the corresponding index.

*Example of failing to check whether the index data field exists:*

.. code-block:: javascript

    if (doc.min_length) {
        index("min_length", doc.min_length, {"store": true});
    }

You might use the JavaScript ``typeof`` function to implement the guard clause test.
If the field exists *and* has the expected type,
the correct type name is returned,
so the guard clause test succeeds and it is safe to use the index function.
If the field does *not* exist,
you would not get back the expected type of the field,
therefore you would not attempt to index the field.

JavaScript considers a result to be false if one of the following values is tested:

* 'undefined'
* null
* The number +0
* The number -0
* NaN (not a number)
* "" (the empty string)

*Using a guard clause to check whether the required data field exists,
and holds a number, before an attempt to index:*

.. code-block:: javascript

    if (typeof(doc.min_length) === 'number') {
        index("min_length", doc.min_length, {"store": true});
    }

Use a generic guard clause test to ensure that the type of the candidate data
field is defined.

*Example of a 'generic' guard clause:*

.. code-block:: javascript

    if (typeof(doc.min_length) !== 'undefined') {
        // The field exists, and does have a type, so we can proceed to index using it.
        ...
    }

.. _api/ddoc/view/analyzers:

Analyzers
---------

Analyzers are settings that define how to recognize terms within text.
Analyzers can be helpful if you need to
:ref:`language-specific-analyzers <api/ddoc/view>`.

Here's the list of generic analyzers that are supported by search:

+----------------+---------------------------------------------------------------------------------+
| Analyzer       | Description                                                                     |
+================+=================================================================================+
| ``classic``    | The standard Lucene analyzer, circa release 3.1.                                |
+----------------+---------------------------------------------------------------------------------+
| ``email``      | Like the ``standard`` analyzer, but tries harder to match an email              |
|                | address as a complete token.                                                    |
+----------------+---------------------------------------------------------------------------------+
| ``keyword``    | Input is not tokenized at all.                                                  |
+----------------+---------------------------------------------------------------------------------+
| ``simple``     | Divides text at non-letters.                                                    |
+----------------+---------------------------------------------------------------------------------+
| ``standard``   | The default analyzer. It implements the Word Break rules from the               |
|                | `Unicode Text Segmentation algorithm <http://www.unicode.org/reports/tr29/>`_.  |
+----------------+---------------------------------------------------------------------------------+
| ``whitespace`` | Divides text at white space boundaries.                                         |
+----------------+---------------------------------------------------------------------------------+

*Example analyzer document:*

.. code-block:: javascript

    {
        "_id": "_design/analyzer_example",
        "indexes": {
            "INDEX_NAME": {
                "index": "function (doc) { ... }",
                "analyzer": "$ANALYZER_NAME"
            }
        }
    }

.. _api/ddoc/view/language-specific-analyzers:

Language-specific analyzers
^^^^^^^^^^^^^^^^^^^^^^^^^^^

These analyzers omit common words in the specific language,
and many also `remove prefixes and suffixes <http://en.wikipedia.org/wiki/Stemming>`_.
The name of the language is also the name of the analyzer.

+----------------+----------------------------------------------------------+
| Language       | Analyzer                                                 |
+================+==========================================================+
| ``arabic``     | org.apache.lucene.analysis.ar.ArabicAnalyzer             |
+----------------+----------------------------------------------------------+
| ``armenian``   | org.apache.lucene.analysis.hy.ArmenianAnalyzer           |
+----------------+----------------------------------------------------------+
| ``basque``     | org.apache.lucene.analysis.eu.BasqueAnalyzer             |
+----------------+----------------------------------------------------------+
| ``bulgarian``  | org.apache.lucene.analysis.bg.BulgarianAnalyzer          |
+----------------+----------------------------------------------------------+
| ``brazilian``  | org.apache.lucene.analysis.br.BrazilianAnalyzer          |
+----------------+----------------------------------------------------------+
| ``catalan``    | org.apache.lucene.analysis.ca.CatalanAnalyzer            |
+----------------+----------------------------------------------------------+
| ``cjk``        | org.apache.lucene.analysis.cjk.CJKAnalyzer               |
+----------------+----------------------------------------------------------+
| ``chinese``    | org.apache.lucene.analysis.cn.smart.SmartChineseAnalyzer |
+----------------+----------------------------------------------------------+
| ``czech``      | org.apache.lucene.analysis.cz.CzechAnalyzer              |
+----------------+----------------------------------------------------------+
| ``danish``     | org.apache.lucene.analysis.da.DanishAnalyzer             |
+----------------+----------------------------------------------------------+
| ``dutch``      | org.apache.lucene.analysis.nl.DutchAnalyzer              |
+----------------+----------------------------------------------------------+
| ``english``    | org.apache.lucene.analysis.en.EnglishAnalyzer            |
+----------------+----------------------------------------------------------+
| ``finnish``    | org.apache.lucene.analysis.fi.FinnishAnalyzer            |
+----------------+----------------------------------------------------------+
| ``french``     | org.apache.lucene.analysis.fr.FrenchAnalyzer             |
+----------------+----------------------------------------------------------+
| ``german``     | org.apache.lucene.analysis.de.GermanAnalyzer             |
+----------------+----------------------------------------------------------+
| ``greek``      | org.apache.lucene.analysis.el.GreekAnalyzer              |
+----------------+----------------------------------------------------------+
| ``galician``   | org.apache.lucene.analysis.gl.GalicianAnalyzer           |
+----------------+----------------------------------------------------------+
| ``hindi``      | org.apache.lucene.analysis.hi.HindiAnalyzer              |
+----------------+----------------------------------------------------------+
| ``hungarian``  | org.apache.lucene.analysis.hu.HungarianAnalyzer          |
+----------------+----------------------------------------------------------+
| ``indonesian`` | org.apache.lucene.analysis.id.IndonesianAnalyzer         |
+----------------+----------------------------------------------------------+
| ``irish``      | org.apache.lucene.analysis.ga.IrishAnalyzer              |
+----------------+----------------------------------------------------------+
| ``italian``    | org.apache.lucene.analysis.it.ItalianAnalyzer            |
+----------------+----------------------------------------------------------+
| ``japanese``   | org.apache.lucene.analysis.ja.JapaneseAnalyzer           |
+----------------+----------------------------------------------------------+
| ``japanese``   | import org.apache.lucene.analysis.ja.JapaneseTokenizer   |
|                | (with DEFAULT_MODE and defaultStopTags)                  |
+----------------+----------------------------------------------------------+
| ``latvian``    | org.apache.lucene.analysis.lv.LatvianAnalyzer            |
+----------------+----------------------------------------------------------+
| ``norwegian``  | org.apache.lucene.analysis.no.NorwegianAnalyzer          |
+----------------+----------------------------------------------------------+
| ``persian``    | org.apache.lucene.analysis.fa.PersianAnalyzer            |
+----------------+----------------------------------------------------------+
| ``polish``     | org.apache.lucene.analysis.pl.PolishAnalyzer             |
+----------------+----------------------------------------------------------+
| ``portuguese`` | org.apache.lucene.analysis.pt.PortugueseAnalyzer         |
+----------------+----------------------------------------------------------+
| ``romanian``   | org.apache.lucene.analysis.ro.RomanianAnalyzer           |
+----------------+----------------------------------------------------------+
| ``russian``    | org.apache.lucene.analysis.ru.RussianAnalyzer            |
+----------------+----------------------------------------------------------+
| ``spanish``    | org.apache.lucene.analysis.es.SpanishAnalyzer            |
+----------------+----------------------------------------------------------+
| ``swedish``    | import org.apache.lucene.analysis.sv.SwedishAnalyzer     |
+----------------+----------------------------------------------------------+
| ``thai``       | import org.apache.lucene.analysis.th.ThaiAnalyzer        |
+----------------+----------------------------------------------------------+
| ``turkish``    | import org.apache.lucene.analysis.tr.TurkishAnalyzer     |
+----------------+----------------------------------------------------------+

.. note::

    Language-specific analyzers are optimized for the specified language. You
    cannot combine a generic analyzer with a language-specific analyzer.
    Instead, you might use a :ref:`per-field-analyzers <api/ddoc/view>` to
    select different analyzers for different fields within the documents.

.. _api/ddoc/view/per-field-analyzers:

Per-field analyzers
^^^^^^^^^^^^^^^^^^^

The ``perfield`` analyzer configures multiple analyzers for different fields.

*Example of defining different analyzers for different fields:*

.. code-block:: javascript

    {
        "_id": "_design/analyzer_example",
        "indexes": {
            "INDEX_NAME": {
                "analyzer": {
                    "name": "perfield",
                    "default": "english",
                    "fields": {
                        "spanish": "spanish",
                        "german": "german"
                    }
                },
                "index": "function (doc) { ... }"
            }
        }
    }

Stop words
^^^^^^^^^^

Stop words are words that do not get indexed. You define them within
a design document by turning the analyzer string into an object.

.. note::

    The ``keyword``, ``simple``, and ``whitespace`` analyzers do not support stop words.

The default stop words for the ``standard`` analyzer are included below:

.. code-block:: javascript

    "a", "an", "and", "are", "as", "at", "be", "but", "by", "for", "if",
    "in", "into", "is", "it", "no", "not", "of", "on", "or", "such",
    "that", "the", "their", "then", "there", "these", "they", "this",
    "to", "was", "will", "with"

*Example of defining non-indexed ('stop') words:*

.. code-block:: javascript

    {
        "_id": "_design/stop_words_example",
        "indexes": {
            "INDEX_NAME": {
                "analyzer": {
                    "name": "portuguese",
                    "stopwords": [
                        "foo",
                        "bar",
                        "baz"
                    ]
                },
                "index": "function (doc) { ... }"
            }
        }
    }

Testing analyzer tokenization
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You can test the results of analyzer tokenization by posting sample data to the
``_search_analyze`` endpoint.

*Example of using HTTP to test the ``keyword`` analyzer:*

.. code-block:: http

    POST /_search_analyze HTTP/1.1
    Content-Type: application/json
    {"analyzer":"keyword", "text":"ablanks@renovations.com"}

*Example of using the command line to test the ``keyword`` analyzer:*

.. code-block:: sh

    curl 'https://$HOST:5984/_search_analyze' -H 'Content-Type: application/json'
        -d '{"analyzer":"keyword", "text":"ablanks@renovations.com"}'

*Result of testing the ``keyword`` analyzer:*

.. code-block:: javascript

    {
        "tokens": [
            "ablanks@renovations.com"
        ]
    }

*Example of using HTTP to test the ``standard`` analyzer:*

.. code-block:: http

    POST /_search_analyze HTTP/1.1
    Content-Type: application/json
    {"analyzer":"standard", "text":"ablanks@renovations.com"}

*Example of using the command line to test the ``standard`` analyzer:*

.. code-block:: sh

    curl 'https://$HOST:5984/_search_analyze' -H 'Content-Type: application/json'
        -d '{"analyzer":"standard", "text":"ablanks@renovations.com"}'

*Result of testing the ``standard`` analyzer:*

.. code-block:: javascript

    {
        "tokens": [
            "ablanks",
            "renovations.com"
        ]
    }

Queries
-------

After you create a search index, you can query it.

- Issue a partition query using:
  ``GET /$DATABASE/_partition/$PARTITION_KEY/_design/$DDOC/_search/$INDEX_NAME``
- Issue a global query using:
  ``GET /$DATABASE/_design/$DDOC/_search/$INDEX_NAME``

Specify your search by using the ``query`` parameter.

*Example of using HTTP to query a partitioned index:*

.. code-block:: http

    GET /$DATABASE/_partition/$PARTITION_KEY/_design/$DDOC/_search/$INDEX_NAME?include_docs=true&query="*:*"&limit=1 HTTP/1.1
    Content-Type: application/json

*Example of using HTTP to query a global index:*

.. code-block:: http

    GET /$DATABASE/_design/$DDOC/_search/$INDEX_NAME?include_docs=true&query="*:*"&limit=1 HTTP/1.1
    Content-Type: application/json

*Example of using the command line to query a partitioned index:*

.. code-block:: sh

    curl https://$HOST:5984/$DATABASE/_partition/$PARTITION_KEY/_design/$DDOC/
    _search/$INDEX_NAME?include_docs=true\&query="*:*"\&limit=1 \

*Example of using the command line to query a global index:*

.. code-block:: sh

    curl https://$HOST:5984/$DATABASE/_design/$DDOC/_search/$INDEX_NAME?
    include_docs=true\&query="*:*"\&limit=1 \

.. _api/ddoc/view/query_parameters:

Query Parameters
^^^^^^^^^^^^^^^^

You must enable :ref:`faceting <api/ddoc/view>` before you can use the
following parameters:

- ``counts``
- ``drilldown``

+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| Argument               | Description                                          | Optional          | Type             | Supported values      | Partitioned query |
+========================+======================================================+===================+==================+=======================+===================+
| ``bookmark``           | A bookmark that was received from a previous search. | yes               | String           |                       | yes               |
|                        | This parameter enables paging through the results.   |                   |                  |                       |                   |
|                        | If there are no more results after the bookmark,     |                   |                  |                       |                   |
|                        | you get a response with an empty rows array and the  |                   |                  |                       |                   |
|                        | same bookmark, confirming the end of the result list.|                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``counts``             | This field defines an array of names of string       | yes               | JSON             | A JSON array of field | no                |
|                        | fields, for which counts are requested. The response |                   |                  | names.                |                   |
|                        | contains counts for each unique value of this        |                   |                  |                       |                   |
|                        | field name among the documents that match the search |                   |                  |                       |                   |
|                        | query. :ref:`faceting <api/ddoc/view>` must          |                   |                  |                       |                   |
|                        | be enabled for this parameter to function.           |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``drilldown``          | This field can be used several times. Each use       | no                | JSON             | A JSON array with two | yes               |
|                        | defines a pair with a field name and a value.        |                   |                  | elements: the field   |                   |
|                        | The search matches only documents containing the     |                   |                  | name and the value.   |                   |
|                        | value that was provided in the named field. It       |                   |                  |                       |                   |
|                        | differs from using ``"fieldname:value"`` in          |                   |                  |                       |                   |
|                        | the ``q`` parameter only in that the values are not  |                   |                  |                       |                   |
|                        | analyzed. :ref:`faceting <api/ddoc/view>` must       |                   |                  |                       |                   |
|                        | be enabled for this parameter to function.           |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``group_field``        | Field that groups search matches                     | yes               |  String          | A string that         | no                |
|                        |                                                      |                   |                  | contains the name of  |                   |
|                        |                                                      |                   |                  | a string field.       |                   |
|                        |                                                      |                   |                  | Fields containing     |                   |
|                        |                                                      |                   |                  | other data such as    |                   |
|                        |                                                      |                   |                  | numbers, objects, or  |                   |
|                        |                                                      |                   |                  | arrays cannot be      |                   |
|                        |                                                      |                   |                  | used.                 |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``group_limit``        | Maximum group count. This field can be used only if  | yes               | Numeric          |                       | no                |
|                        | ``group_field`` is specified.                        |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``group_sort``         | This field defines the order of the groups in a      | yes               | JSON             | This field can have   | no                |
|                        | search that uses ``group_field``. The default sort   |                   |                  | the same values as    |                   |
|                        | order is relevance.                                  |                   |                  | the sort field, so    |                   |
|                        |                                                      |                   |                  | single fields and     |                   |
|                        |                                                      |                   |                  | arrays of fields are  |                   |
|                        |                                                      |                   |                  | supported.            |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``highlight_fields``   | Specifies which fields to highlight. If specified,   | yes               | Array of strings |                       | no                |
|                        | the result object contains a ``highlights`` field    |                   |                  |                       |                   |
|                        | with an entry for each specified field.              |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``highlight_pre_tag``  | A string that is inserted before the highlighted     | yes, defaults     | String           |                       | yes               |
|                        | word in the highlights output.                       | to ``<em>``       |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``highlight_post_tag`` | A string that is inserted after the highlighted word | yes, defaults     | String           |                       | yes               |
|                        | in the highlights output.                            | to ``</em>``      |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``highlight_number``   | Number of fragments that are returned in highlights. | yes, defaults     | Numeric          |                       | yes               |
|                        | If the search term occurs less often than the number | to 1              |                  |                       |                   |
|                        | of fragments that are specified, longer fragments    |                   |                  |                       |                   |
|                        | are returned.                                        |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``highlight_size``     | Number of characters in each fragment for            | yes, defaults to  | Numeric          |                       | yes               |
|                        | highlights.                                          | 100 characters    |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``include_docs``       | Include the full content of the documents in the     | yes               | Boolean          |                       | yes               |
|                        | response.                                            |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``include_fields``     | A JSON array of field names to include in search     | yes, the default  | Array of strings |                       | yes               |
|                        | results. Any fields that are included must be        | is all fields     |                  |                       |                   |
|                        | indexed with the ``store:true`` option.              |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``limit``              | Limit the number of the returned documents to the    | yes               | Numeric          | The limit value can   | yes               |
|                        | specified number. For a grouped search, this         |                   |                  | be any positive       |                   |
|                        | parameter limits the number of documents per group.  |                   |                  | integer number up to  |                   |
|                        |                                                      |                   |                  | and including 200.    |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``q``                  | Abbreviation for ``query``. Runs a Lucene query.     | no                | String or number |                       | yes               |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``query``              | Runs a Lucene query.                                 | no                | String or number |                       | yes               |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``ranges``             | This field defines ranges for faceted, numeric       | yes               | JSON             | The value must be an  | no                |
|                        | search fields. The value is a JSON object where      |                   |                  | object with fields    |                   |
|                        | the fields names are faceted numeric search fields,  |                   |                  | that have objects as  |                   |
|                        | and the values of the fields are JSON objects. The   |                   |                  | their values. These   |                   |
|                        | field names of the JSON objects are names for        |                   |                  | objects must have     |                   |
|                        | ranges. The values are strings that describe the     |                   |                  | strings with ranges   |                   |
|                        | range, for example ``"[0 TO 10]"``.                  |                   |                  | as their field        |                   |
|                        |                                                      |                   |                  | values.               |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``sort``               | Specifies the sort order of the results. In a        | yes               | JSON             | A JSON string of the  | yes               |
|                        | grouped search (when ``group_field`` is              |                   |                  | form                  |                   |
|                        | used), this parameter specifies the sort order       |                   |                  | ``"fieldname<type>"`` |                   |
|                        | within a group. The default sort order is relevance. |                   |                  | or                    |                   |
|                        |                                                      |                   |                  | ``-fieldname<type>``  |                   |
|                        |                                                      |                   |                  | for descending order, |                   |
|                        |                                                      |                   |                  | where ``fieldname``   |                   |
|                        |                                                      |                   |                  | is the name of a      |                   |
|                        |                                                      |                   |                  | string or number      |                   |
|                        |                                                      |                   |                  | field, and ``type``   |                   |
|                        |                                                      |                   |                  | is either a number, a |                   |
|                        |                                                      |                   |                  | string, or a JSON     |                   |
|                        |                                                      |                   |                  | array of strings. The |                   |
|                        |                                                      |                   |                  | ``type`` part is      |                   |
|                        |                                                      |                   |                  | optional, and         |                   |
|                        |                                                      |                   |                  | defaults to           |                   |
|                        |                                                      |                   |                  | ``number``. Some      |                   |
|                        |                                                      |                   |                  | examples are          |                   |
|                        |                                                      |                   |                  | ``"foo"``,            |                   |
|                        |                                                      |                   |                  | ``"-foo"``,           |                   |
|                        |                                                      |                   |                  | ``"bar<string>"``,    |                   |
|                        |                                                      |                   |                  | ``"-foo<number>"``    |                   |
|                        |                                                      |                   |                  | and ,                 |                   |
|                        |                                                      |                   |                  | ``["-foo<number>"     |                   |
|                        |                                                      |                   |                  | "bar<string>"]``.     |                   |
|                        |                                                      |                   |                  | String fields that    |                   |
|                        |                                                      |                   |                  | are used for sorting  |                   |
|                        |                                                      |                   |                  | must not be analyzed  |                   |
|                        |                                                      |                   |                  | fields. Fields that   |                   |
|                        |                                                      |                   |                  | are used for sorting  |                   |
|                        |                                                      |                   |                  | must be indexed by    |                   |
|                        |                                                      |                   |                  | the same indexer that |                   |
|                        |                                                      |                   |                  | is used for the       |                   |
|                        |                                                      |                   |                  | search query.         |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+
| ``stale``              | Do not wait for the index to finish building to      | yes               | String           | OK                    | yes               |
|                        | return results.                                      |                   |                  |                       |                   |
+------------------------+------------------------------------------------------+-------------------+------------------+-----------------------+-------------------+

.. note::
    Do not combine the ``bookmark`` and ``stale`` options. These options
    constrain the choice of shard replicas to use for the response. When used
    together, the options might cause problems when contact is attempted
    with replicas that are slow or not available.

Relevance
^^^^^^^^^

When more than one result might be returned,
it is possible for them to be sorted.
By default,
the sorting order is determined by 'relevance'.

Relevance is measured according to
`Apache Lucene Scoring <https://lucene.apache.org/core/3_6_0/scoring.html>`_.
As an example,
if you search a simple database for the word ``example``,
two documents might contain the word.
If one document mentions the word ``example`` 10 times,
but the second document mentions it only twice,
then the first document is considered to be more 'relevant'.

If you do not provide a ``sort`` parameter,
relevance is used by default.
The highest scoring matches are returned first.

If you provide a ``sort`` parameter,
then matches are returned in that order,
ignoring relevance.

If you want to use a ``sort`` parameter,
and also include ordering by relevance in your search results,
use the special fields ``-<score>`` or ``<score>`` within the ``sort`` parameter.

POSTing search queries
^^^^^^^^^^^^^^^^^^^^^^

Instead of using the ``GET`` HTTP method,
you can also use ``POST``.
The main advantage of ``POST`` queries is that they can have a request body,
so you can specify the request as a JSON object.
Each parameter in the previous table corresponds to a field in the JSON object
in the request body.

*Example of using HTTP to ``POST`` a search request:*

.. code-block:: http

    POST /db/_design/ddoc/_search/searchname HTTP/1.1
    Content-Type: application/json

*Example of using the command line to ``POST`` a search request:*

.. code-block:: sh

    curl 'https://$HOST:5984/db/_design/ddoc/_search/searchname' -X POST -H 'Content-Type: application/json' -d @search.json

*Example JSON document that contains a search request:*

.. code-block:: javascript

    {
        "q": "index:my query",
        "sort": "foo",
        "limit": 3
    }

Query syntax
------------

The CouchDB search query syntax is based on the
`Lucene syntax <http://lucene.apache.org/core/4_3_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#Overview>`_.
Search queries take the form of ``name:value`` unless the name is omitted,
in which case they use the default field,
as demonstrated in the following examples:

*Example search query expressions:*

.. code-block:: javascript

    // Birds
    class:bird

.. code-block:: text

    // Animals that begin with the letter "l"
    l*

.. code-block:: text

    // Carnivorous birds
    class:bird AND diet:carnivore

.. code-block:: text

    // Herbivores that start with letter "l"
    l* AND diet:herbivore

.. code-block:: text

    // Medium-sized herbivores
    min_length:[1 TO 3] AND diet:herbivore

.. code-block:: text

    // Herbivores that are 2m long or less
    diet:herbivore AND min_length:[-Infinity TO 2]

.. code-block:: text

    // Mammals that are at least 1.5m long
    class:mammal AND min_length:[1.5 TO Infinity]

.. code-block:: text

    // Find "Meles meles"
    latin_name:"Meles meles"

.. code-block:: text

    // Mammals who are herbivore or carnivore
    diet:(herbivore OR omnivore) AND class:mammal

.. code-block:: text

    // Return all results
    *:*

Queries over multiple fields can be logically combined,
and groups and fields can be further grouped.
The available logical operators are case-sensitive and are ``AND``, ``+``, ``OR``, ``NOT`` and ``-``.
Range queries can run over strings or numbers.

If you want a fuzzy search,
you can run a query with ``~`` to find terms like the search term.
For instance,
``look~`` finds the terms ``book`` and ``took``.

.. note::
    If the lower and upper bounds of a range query are both strings that
    contain only numeric digits, the bounds are treated as numbers not as
    strings. For example, if you search by using the query
    ``mod_date:["20170101" TO "20171231"]``, the results include documents
    for which ``mod_date`` is between the numeric values 20170101 and
    20171231, not between the strings "20170101" and "20171231".

You can alter the importance of a search term by adding ``^`` and a positive number.
This alteration makes matches containing the term more or less relevant,
proportional to the power of the boost value.
The default value is 1,
which means no increase or decrease in the strength of the match.
A decimal value of 0 - 1 reduces importance.
making the match strength weaker.
A value greater than one increases importance,
making the match strength stronger.

Wildcard searches are supported,
for both single (``?``) and multiple (``*``) character searches.
For example,
``dat?`` would match ``date`` and ``data``,
whereas ``dat*`` would match ``date``,
``data``,
``database``,
and ``dates``.
Wildcards must come after the search term.

Use ``*:*`` to return all results.

Result sets from searches are limited to 200 rows,
and return 25 rows by default.
The number of rows that are returned can be changed
by using the :ref:`query-parameters <api/ddoc/view>`.

If the search query does *not* specify the ``"group_field"`` argument,
the response contains a bookmark.
If this bookmark is later provided as a URL parameter,
the response skips the rows that were seen already,
making it quick and easy to get the next set of results.

.. note::
    The response never includes a bookmark if the ``"group_field"``
    parameter is included in the search query. For more information,
    see :ref:`query-parameters <api/ddoc/view>`.

.. note::
    The ``group_field``, ``group_limit``, and ``group_sort`` options
    are only available when making global queries.

The following characters require escaping if you want to search on them:

.. code-block:: sh

    + - && || ! ( ) { } [ ] ^ " ~ * ? : \ /

To escape one of these characters,
use a preceding backslash character (``\``).

The response to a search query contains an ``order`` field
for each of the results.
The ``order`` field is an array where the first element is
the field or fields that are specified
in the ``sort`` parameter. See :ref:`query-parameters <api/ddoc/view>`.
If no ``sort`` parameter is included in the query,
then the ``order`` field contains the
`Lucene relevance score <https://lucene.apache.org/core/3_6_0/scoring.html>`_.
If you use the 'sort by distance' feature as described
in :ref:`geographical-searches <api/ddoc/view>`,
then the first element is the distance from a point.
The distance is measured by using either kilometers or miles.

.. note::
    The second element in the order array can be ignored.
    It is used for troubleshooting purposes only.

.. _api/ddoc/view/faceting:

Faceting
^^^^^^^^

CouchDB Search also supports faceted searching,
enabling discovery of aggregate information about matches quickly and easily.
You can match all documents by using the special ``?q=*:*`` query syntax,
and use the returned facets to refine your query.
To indicate that a field must be indexed for faceted queries,
set ``{"facet": true}`` in its options.

*Example of search query, specifying that faceted search is enabled:*

.. code-block:: javascript

    function(doc) {
        index("type", doc.type, {"facet": true});
        index("price", doc.price, {"facet": true});
    }

To use facets,
all the documents in the index must include all the fields
that have faceting enabled.
If your documents do not include all the fields,
you receive a ``bad_request`` error with the following reason,
"The ``field_name`` does not exist."
If each document does not contain all the fields for facets,
create separate indexes for each field.
If you do not create separate indexes for each field,
you must include only documents that contain all the fields.
Verify that the fields exist in each document by using a single ``if`` statement.

*Example ``if`` statement to verify that the required fields exist
in each document:*

.. code-block:: javascript

    if (typeof doc.town == "string" && typeof doc.name == "string") {
        index("town", doc.town, {facet: true});
        index("name", doc.name, {facet: true});
       }

Counts
^^^^^^

.. note::
    The ``counts`` option is only available when making global queries.

The ``counts`` facet syntax takes a list of fields,
and returns the number of query results for each unique
value of each named field.

.. note::
    The ``count`` operation works only if the indexed values are strings.
    The indexed values cannot be mixed types. For example,
    if 100 strings are indexed, and one number,
    then the index cannot be used for ``count`` operations.
    You can check the type by using the ``typeof`` operator, and convert it
    by using the ``parseInt``,
    ``parseFloat``, or ``.toString()`` functions.

*Example of a query using the ``counts`` facet syntax:*

.. code-block:: http

    ?q=*:*&counts=["type"]

*Example response after using of the ``counts`` facet syntax:*

.. code-block:: javascript

    {
        "total_rows":100000,
        "bookmark":"g...",
        "rows":[...],
        "counts":{
            "type":{
                "sofa": 10,
                "chair": 100,
                "lamp": 97
            }
        }
    }

``drilldown``
^^^^^^^^^^^^^

.. note::
    The ``drilldown`` option is only available when making global queries.

You can restrict results to documents with a dimension equal to
the specified label.
Restrict the results by adding ``drilldown=["dimension","label"]``
to a search query.
You can include multiple ``drilldown`` parameters to restrict results
along multiple dimensions.

Using a ``drilldown`` parameter is similar to using ``key:value`` in
the ``q`` parameter,
but the ``drilldown`` parameter returns values that the analyzer might skip.

For example,
if the analyzer did not index a stop word like ``"a"``,
using ``drilldown`` returns it when you specify
``drilldown=["key","a"]``.

Ranges
^^^^^^

.. note::
    The ``ranges`` option is only available when making global queries.

The ``range`` facet syntax reuses the standard Lucene syntax for ranges
to return counts of results that fit into each specified category.
Inclusive range queries are denoted by brackets (``[``, ``]``).
Exclusive range queries are denoted by curly brackets (``{``, ``}``).

.. note::
    The ``range`` operation works only if the indexed values are numbers.
    The indexed values cannot be mixed types. For example, if 100 strings
    are indexed,
    and one number, then the index cannot be used for ``range`` operations.
    You can check the type by using the ``typeof`` operator, and convert
    it by using the ``parseInt``, ``parseFloat``, or ``.toString()`` functions.

*Example of a request that uses faceted search for matching ``ranges``:*

.. code-block:: http

    ?q=*:*&ranges={"price":{"cheap":"[0 TO 100]","expensive":"{100 TO Infinity}"}}

*Example results after a ``ranges`` check on a faceted search:*

.. code-block:: javascript

    {
        "total_rows":100000,
        "bookmark":"g...",
        "rows":[...],
        "ranges": {
            "price": {
                "expensive": 278682,
                "cheap": 257023
            }
        }
    }

.. _api/ddoc/view/geographical_searches:

Geographical searches
---------------------

In addition to searching by the content of textual fields,
you can also sort your results by their distance from a geographic coordinate.

To sort your results in this way,
you must index two numeric fields,
representing the longitude and latitude.

.. note::
    You can also sort your results by their distance from a geographic coordinate
    using Lucene's built-in geospatial capabilities.

You can then query by using the special ``<distance...>`` sort field,
which takes five parameters:

- Longitude field name: The name of your longitude field (``mylon`` in the example).

- Latitude field name: The name of your latitude field (``mylat`` in the example).

- Longitude of origin: The longitude of the place you want to sort by distance from.

- Latitude of origin: The latitude of the place you want to sort by distance from.

- Units: The units to use: ``km`` for kilometers or ``mi`` for miles.
  The distance is returned in the order field.

You can combine sorting by distance with any other search query,
such as range searches on the latitude and longitude,
or queries that involve non-geographical information.

That way,
you can search in a bounding box,
and narrow down the search with extra criteria.

*Example geographical data:*

.. code-block:: javascript

    {
        "name":"Aberdeen, Scotland",
        "lat":57.15,
        "lon":-2.15,
        "type":"city"
    }

*Example of a design document that contains a search index for the geographic data:*

.. code-block:: javascript

    function(doc) {
        if (doc.type && doc.type == 'city') {
            index('city', doc.name, {'store': true});
            index('lat', doc.lat, {'store': true});
            index('lon', doc.lon, {'store': true});
        }
    }

*An example of using HTTP for a query that sorts cities in the northern hemisphere by
their distance to New York:*

.. code-block:: http

    GET /examples/_design/cities-designdoc/_search/cities?q=lat:[0+TO+90]&sort="<distance,lon,lat,-74.0059,40.7127,km>" HTTP/1.1

*An example of using the command line for a query that sorts cities in the northern hemisphere by their distance to New York:*

.. code-block:: sh

    curl 'https://$HOST:5984/examples/_design/cities-designdoc/_search/cities?q=lat:[0+TO+90]&sort="<distance,lon,lat,-74.0059,40.7127,km>"'

*Example (abbreviated) response, containing a list of northern hemisphere
cities sorted by distance to New York:*

.. code-block:: javascript

    {
        "total_rows": 205,
        "bookmark": "g1A...XIU",
        "rows": [
            {
                "id": "city180",
                "order": [
                    8.530665755719783,
                    18
                ],
                "fields": {
                    "city": "New York, N.Y.",
                    "lat": 40.78333333333333,
                    "lon": -73.96666666666667
                }
            },
            {
                "id": "city177",
                "order": [
                    13.756343205985946,
                    17
                ],
                "fields": {
                    "city": "Newark, N.J.",
                    "lat": 40.733333333333334,
                    "lon": -74.16666666666667
                }
            },
            {
                "id": "city178",
                "order": [
                    113.53603438866077,
                    26
                ],
                "fields": {
                    "city": "New Haven, Conn.",
                    "lat": 41.31666666666667,
                    "lon": -72.91666666666667
                }
            }
        ]
    }

Highlighting search terms
-------------------------

Sometimes it is useful to get the context in which a search
term was mentioned
so that you can display more emphasized results to a user.

To get more emphasized results,
add the ``highlight_fields`` parameter to the search query.
Specify the field names for which you would like excerpts,
with the highlighted search term returned.

By default,
the search term is placed in ``<em>`` tags to highlight it,
but the highlight can be overridden by using the ``highlights_pre_tag``
and ``highlights_post_tag`` parameters.

The length of the fragments is 100 characters by default.
A different length can be requested with the ``highlights_size`` parameter.

The ``highlights_number`` parameter controls the number of fragments
that are returned, and defaults to 1.

In the response,
a ``highlights`` field is added,
with one subfield per field name.

For each field,
you receive an array of fragments with the search term highlighted.

.. note::
    For highlighting to work, store the field in the index by
    using the ``store: true`` option.

*Example of using HTTP to search with highlighting enabled:*

.. code-block:: http

    GET /movies/_design/searches/_search/movies?q=movie_name:Azazel&highlight_fields=["movie_name"]&highlight_pre_tag="**"&highlight_post_tag="**"&highlights_size=30&highlights_number=2 HTTP/1.1
    Authorization: ...

*Example of using the command line to search with
highlighting enabled:*

.. code-block:: sh

    curl "https://$HOST:5984/movies/_design/searches/_search/movies?q=movie_name:Azazel&highlight_fields=\[\"movie_name\"\]&highlight_pre_tag=\"**\"&highlight_post_tag=\"**\"&highlights_size=30&highlights_number=2

*Example of highlighted search results:*

.. code-block:: javascript

    {
        "highlights": {
            "movie_name": [
                " on the Azazel Orient Express",
                " Azazel manuals, you"
            ]
        }
    }

Search index metadata
---------------------

To retrieve information about a search index,
you send a ``GET`` request to the ``_search_info`` endpoint,
as shown in the following example.
``DDOC`` refers to the design document that contains the index,
and ``INDEX_NAME`` is the name of the index.

*Example of using HTTP to request search index metadata:*

.. code-block:: http

    GET /$DATABASE/_design/$DDOC/_search_info/$INDEX_NAME HTTP/1.1

*Example of using the command line to request search index metadata:*

.. code-block:: sh

    curl "https://$HOST:5984/$DATABASE/_design/$DDOC/_search_info/$INDEX_NAME" \
         -X GET

The response contains information about your index,
such as the number of documents in the index and the size of
the index on disk.

*Example response after requesting search index metadata:*

.. code-block:: javascript

    {
        "name": "_design/DDOC/INDEX",
        "search_index": {
            "pending_seq": 7125496,
            "doc_del_count": 129180,
            "doc_count": 1066173,
            "disk_size": 728305827,
            "committed_seq": 7125496
        }
    }

``dreyfus``
-----------

``name`` = ``clouseau@127.0.0.1``
The name and location of the Clouseau Java service required to
enable Search functionality.

``retry_limit`` = 5
CouchDB will try to reconnect to Clouseau using a bounded
exponential backoff with the following number of iterations.

``limit`` = 25
The default number of results returned from a global search query.

``limit_partitions`` = 2000
The default number of results returned from a search on a partition
of a database.

``max_limit`` = 200
The maximum number of results that can be returned from a global
search query (or any search query on a database without user-defined
partitions). Attempts to set ``?limit=N higher`` than this value will
be rejected.

``max_limit_partitions`` = 2000
The maximum number of results that can be returned when searching
a partition of a database. Attempts to set ``?limit=N`` higher than this
value will be rejected. If this config setting is not defined,
CouchDB will use the value of ``max_limit`` instead. If neither is
defined, the default is 2000 as stated here.

.. _api/ddoc/view/sorting:

Sorting Returned Rows
=====================

Each element within the returned array is sorted using
native UTF-8 sorting
according to the contents of the key portion of the
emitted content. The basic
order of output is as follows:

- ``null``

- ``false``

- ``true``

- Numbers

- Text (case sensitive, lowercase first)

- Arrays (according to the values of each element, in order)

- Objects (according to the values of keys, in key order)

**Request**:

.. code-block:: http

    GET /db/_design/test/_view/sorting HTTP/1.1
    Accept: application/json
    Host: localhost:5984

**Response**:

.. code-block:: http

    HTTP/1.1 200 OK
    Cache-Control: must-revalidate
    Content-Type: application/json
    Date: Wed, 21 Aug 2013 10:09:25 GMT
    ETag: "8LA1LZPQ37B6R9U8BK9BGQH27"
    Server: CouchDB (Erlang/OTP)
    Transfer-Encoding: chunked

    {
        "offset": 0,
        "rows": [
            {
                "id": "dummy-doc",
                "key": null,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": false,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": true,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 0,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 1,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 10,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 42,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "10",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "hello",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "Hello",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "\u043f\u0440\u0438\u0432\u0435\u0442",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [
                    1,
                    2,
                    3
                ],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [
                    2,
                    3
                ],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [
                    3
                ],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": {},
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": {
                    "foo": "bar"
                },
                "value": null
            }
        ],
        "total_rows": 17
    }

You can reverse the order of the returned view information
by using the ``descending`` query value set to true:

**Request**:

.. code-block:: http

    GET /db/_design/test/_view/sorting?descending=true HTTP/1.1
    Accept: application/json
    Host: localhost:5984

**Response**:

.. code-block:: http

    HTTP/1.1 200 OK
    Cache-Control: must-revalidate
    Content-Type: application/json
    Date: Wed, 21 Aug 2013 10:09:25 GMT
    ETag: "Z4N468R15JBT98OM0AMNSR8U"
    Server: CouchDB (Erlang/OTP)
    Transfer-Encoding: chunked

    {
        "offset": 0,
        "rows": [
            {
                "id": "dummy-doc",
                "key": {
                    "foo": "bar"
                },
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": {},
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [
                    3
                ],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [
                    2,
                    3
                ],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [
                    1,
                    2,
                    3
                ],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": [],
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "\u043f\u0440\u0438\u0432\u0435\u0442",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "Hello",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "hello",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": "10",
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 42,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 10,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 1,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": 0,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": true,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": false,
                "value": null
            },
            {
                "id": "dummy-doc",
                "key": null,
                "value": null
            }
        ],
        "total_rows": 17
    }

Sorting order and startkey/endkey
---------------------------------

The sorting direction is applied before the filtering applied using the
``startkey`` and ``endkey`` query arguments. For example the following query:

.. code-block:: http

    GET http://couchdb:5984/recipes/_design/recipes/_view/by_ingredient?startkey=%22carrots%22&endkey=%22egg%22 HTTP/1.1
    Accept: application/json

will operate correctly when listing all the matching entries between
``carrots`` and ``egg``. If the order of output is reversed with the
``descending`` query argument, the view request will return no entries:

.. code-block:: http

    GET /recipes/_design/recipes/_view/by_ingredient?descending=true&startkey=%22carrots%22&endkey=%22egg%22 HTTP/1.1
    Accept: application/json
    Host: localhost:5984

    {
        "total_rows" : 26453,
        "rows" : [],
        "offset" : 21882
    }

The results will be empty because the entries in the view are reversed before
the key filter is applied, and therefore the ``endkey`` of “egg” will be seen
before the ``startkey`` of “carrots”, resulting in an empty list.

Instead, you should reverse the values supplied to the ``startkey`` and
``endkey`` parameters to match the descending sorting applied to the keys.
Changing the previous example to:

.. code-block:: http

    GET /recipes/_design/recipes/_view/by_ingredient?descending=true&startkey=%22egg%22&endkey=%22carrots%22 HTTP/1.1
    Accept: application/json
    Host: localhost:5984

.. _api/ddoc/view/sorting/raw:

Raw collation
-------------

By default CouchDB using `ICU`_ driver for sorting view results. It's possible
use binary collation instead for faster view builds where Unicode collation is
not important.

To use raw collation add ``"collation": "raw"`` key-value pair to the design
documents ``options`` object at the root level. After that, views will be
regenerated and new order applied.

.. seealso::
    :ref:`views/collation`

.. _ICU: http://site.icu-project.org/

.. _api/ddoc/view/limiting:

Using Limits and Skipping Rows
==============================

By default, views return all results. That's ok when the number of results is
small, but this may lead to problems when there are billions results, since the
client may have to read them all and consume all available memory.

But it's possible to reduce output result rows by specifying ``limit`` query
parameter. For example, retrieving the list of recipes using the ``by_title``
view and limited to 5 returns only 5 records, while there are total 2667
records in view:

**Request**:

.. code-block:: http

    GET /recipes/_design/recipes/_view/by_title?limit=5 HTTP/1.1
    Accept: application/json
    Host: localhost:5984

**Response**:

.. code-block:: http

    HTTP/1.1 200 OK
    Cache-Control: must-revalidate
    Content-Type: application/json
    Date: Wed, 21 Aug 2013 09:14:13 GMT
    ETag: "9Q6Q2GZKPH8D5F8L7PB6DBSS9"
    Server: CouchDB (Erlang/OTP)
    Transfer-Encoding: chunked

    {
        "offset" : 0,
        "rows" : [
            {
                "id" : "3-tiersalmonspinachandavocadoterrine",
                "key" : "3-tier salmon, spinach and avocado terrine",
                "value" : [
                    null,
                    "3-tier salmon, spinach and avocado terrine"
                ]
            },
            {
                "id" : "Aberffrawcake",
                "key" : "Aberffraw cake",
                "value" : [
                    null,
                    "Aberffraw cake"
                ]
            },
            {
                "id" : "Adukiandorangecasserole-microwave",
                "key" : "Aduki and orange casserole - microwave",
                "value" : [
                    null,
                    "Aduki and orange casserole - microwave"
                ]
            },
            {
                "id" : "Aioli-garlicmayonnaise",
                "key" : "Aioli - garlic mayonnaise",
                "value" : [
                    null,
                    "Aioli - garlic mayonnaise"
                ]
            },
            {
                "id" : "Alabamapeanutchicken",
                "key" : "Alabama peanut chicken",
                "value" : [
                    null,
                    "Alabama peanut chicken"
                ]
            }
        ],
        "total_rows" : 2667
    }

To omit some records you may use ``skip`` query parameter:

**Request**:

.. code-block:: http

    GET /recipes/_design/recipes/_view/by_title?limit=3&skip=2 HTTP/1.1
    Accept: application/json
    Host: localhost:5984

**Response**:

.. code-block:: http

    HTTP/1.1 200 OK
    Cache-Control: must-revalidate
    Content-Type: application/json
    Date: Wed, 21 Aug 2013 09:14:13 GMT
    ETag: "H3G7YZSNIVRRHO5FXPE16NJHN"
    Server: CouchDB (Erlang/OTP)
    Transfer-Encoding: chunked

    {
        "offset" : 2,
        "rows" : [
            {
                "id" : "Adukiandorangecasserole-microwave",
                "key" : "Aduki and orange casserole - microwave",
                "value" : [
                    null,
                    "Aduki and orange casserole - microwave"
                ]
            },
            {
                "id" : "Aioli-garlicmayonnaise",
                "key" : "Aioli - garlic mayonnaise",
                "value" : [
                    null,
                    "Aioli - garlic mayonnaise"
                ]
            },
            {
                "id" : "Alabamapeanutchicken",
                "key" : "Alabama peanut chicken",
                "value" : [
                    null,
                    "Alabama peanut chicken"
                ]
            }
        ],
        "total_rows" : 2667
    }

.. warning::
    Using ``limit`` and ``skip`` parameters is not recommended for results
    pagination. Read :ref:`pagination recipe <views/pagination>` why it's so
    and how to make it better.

.. _api/ddoc/view/multiple_queries:

Sending multiple queries to a view
==================================

.. versionadded:: 2.2

.. http:post:: /{db}/_design/{ddoc}/_view/{view}/queries
    :synopsis: Returns results for the specified queries

    Executes multiple specified view queries against the view function
    from the specified design document.

    :param db: Database name
    :param ddoc: Design document name
    :param view: View function name

    :<header Content-Type: - :mimetype:`application/json`
    :<header Accept: - :mimetype:`application/json`

    :<json queries:  An array of query objects with fields for the
        parameters of each individual view query to be executed. The field names
        and their meaning are the same as the query parameters of a
        regular :ref:`view request <api/ddoc/view>`.

    :>header Content-Type: - :mimetype:`application/json`
    :>header ETag: Response signature
    :>header Transfer-Encoding: ``chunked``

    :>json array results: An array of result objects - one for each query. Each
        result object contains the same fields as the response to a regular
        :ref:`view request <api/ddoc/view>`.

    :code 200: Request completed successfully
    :code 400: Invalid request
    :code 401: Read permission required
    :code 404: Specified database, design document or view is missing
    :code 500: View function execution error

**Request**:

.. code-block:: http

    POST /recipes/_design/recipes/_view/by_title/queries HTTP/1.1
    Content-Type: application/json
    Accept: application/json
    Host: localhost:5984

    {
        "queries": [
            {
                "keys": [
                    "meatballs",
                    "spaghetti"
                ]
            },
            {
                "limit": 3,
                "skip": 2
            }
        ]
    }

**Response**:

.. code-block:: http

    HTTP/1.1 200 OK
    Cache-Control: must-revalidate
    Content-Type: application/json
    Date: Wed, 20 Dec 2016 11:17:07 GMT
    ETag: "1H8RGBCK3ABY6ACDM7ZSC30QK"
    Server: CouchDB (Erlang/OTP)
    Transfer-Encoding: chunked

    {
        "results" : [
            {
                "offset": 0,
                "rows": [
                    {
                        "id": "SpaghettiWithMeatballs",
                        "key": "meatballs",
                        "value": 1
                    },
                    {
                        "id": "SpaghettiWithMeatballs",
                        "key": "spaghetti",
                        "value": 1
                    },
                    {
                        "id": "SpaghettiWithMeatballs",
                        "key": "tomato sauce",
                        "value": 1
                    }
                ],
                "total_rows": 3
            },
            {
                "offset" : 2,
                "rows" : [
                    {
                        "id" : "Adukiandorangecasserole-microwave",
                        "key" : "Aduki and orange casserole - microwave",
                        "value" : [
                            null,
                            "Aduki and orange casserole - microwave"
                        ]
                    },
                    {
                        "id" : "Aioli-garlicmayonnaise",
                        "key" : "Aioli - garlic mayonnaise",
                        "value" : [
                            null,
                            "Aioli - garlic mayonnaise"
                        ]
                    },
                    {
                        "id" : "Alabamapeanutchicken",
                        "key" : "Alabama peanut chicken",
                        "value" : [
                            null,
                            "Alabama peanut chicken"
                        ]
                    }
                ],
                "total_rows" : 2667
            }
        ]
    }

.. warning::
    Using POST to /{db}/_design/{ddoc}/_view/{view} is still supported and
    allows you to get multiple query result to a view. This is described
    below. However, this is not encouraged after using POST to
    /{db}/_design/{ddoc}/_view/{view}/queries is introduced.

.. http:post:: /{db}/_design/{ddoc}/_view/{view}
    :synopsis: Returns results for the specified queries

    Executes multiple specified view queries against the view function
    from the specified design document.

    :param db: Database name
    :param ddoc: Design document name
    :param view: View function name

    :<header Content-Type: - :mimetype:`application/json`
    :<header Accept: - :mimetype:`application/json`
                     - :mimetype:`text/plain`

    :query json queries: An array of query objects with fields for the
        parameters of each individual view query to be executed. The field names
        and their meaning are the same as the query parameters of a
        regular :ref:`view request <api/ddoc/view>`.

    :>header Content-Type: - :mimetype:`application/json`
                           - :mimetype:`text/plain; charset=utf-8`
    :>header ETag: Response signature
    :>header Transfer-Encoding: ``chunked``

    :>json array results: An array of result objects - one for each query. Each
        result object contains the same fields as the response to a regular
        :ref:`view request <api/ddoc/view>`.

    :code 200: Request completed successfully
    :code 400: Invalid request
    :code 401: Read permission required
    :code 404: Specified database, design document or view is missed
    :code 500: View function execution error

**Request**:

.. code-block:: http

    POST /recipes/_design/recipes/_view/by_title HTTP/1.1
    Content-Type: application/json
    Accept: application/json
    Host: localhost:5984

    {
        "queries": [
            {
                "keys": [
                    "meatballs",
                    "spaghetti"
                ]
            },
            {
                "limit": 3,
                "skip": 2
            }
        ]
    }

**Response**:

.. code-block:: http

    HTTP/1.1 200 OK
    Cache-Control: must-revalidate
    Content-Type: application/json
    Date: Wed, 07 Sep 2016 11:17:07 GMT
    ETag: "1H8RGBCK3ABY6ACDM7ZSC30QK"
    Server: CouchDB (Erlang/OTP)
    Transfer-Encoding: chunked

    {
        "results" : [
            {
                "offset": 0,
                "rows": [
                    {
                        "id": "SpaghettiWithMeatballs",
                        "key": "meatballs",
                        "value": 1
                    },
                    {
                        "id": "SpaghettiWithMeatballs",
                        "key": "spaghetti",
                        "value": 1
                    },
                    {
                        "id": "SpaghettiWithMeatballs",
                        "key": "tomato sauce",
                        "value": 1
                    }
                ],
                "total_rows": 3
            },
            {
                "offset" : 2,
                "rows" : [
                    {
                        "id" : "Adukiandorangecasserole-microwave",
                        "key" : "Aduki and orange casserole - microwave",
                        "value" : [
                            null,
                            "Aduki and orange casserole - microwave"
                        ]
                    },
                    {
                        "id" : "Aioli-garlicmayonnaise",
                        "key" : "Aioli - garlic mayonnaise",
                        "value" : [
                            null,
                            "Aioli - garlic mayonnaise"
                        ]
                    },
                    {
                        "id" : "Alabamapeanutchicken",
                        "key" : "Alabama peanut chicken",
                        "value" : [
                            null,
                            "Alabama peanut chicken"
                        ]
                    }
                ],
                "total_rows" : 2667
            }
        ]
    }