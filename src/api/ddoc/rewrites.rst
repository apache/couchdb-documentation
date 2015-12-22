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

.. _api/ddoc/rewrite:

========================================
``/db/_design/design-doc/_rewrite/path``
========================================

.. http:any:: /{db}/_design/{ddoc}/_rewrite/{path}
    :synopsis: Rewrites HTTP request for the specified path by using stored
               array of routing rules or javascript function

    Rewrites the specified path by rules defined in the specified design
    document. The rewrite rules are defined in *array* or *string* field
    of the design document called ``rewrites``.

Rewrite section a is stringified function
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    *'Rewrite using JS' feature was introduced in CouchDB 1.7*. If the
    ``rewrites`` field is a stringified function, query server is used
    to pre-process and route a request.

    The function receives truncated version of req object as a single argument
    and must return object, containing new information about request.

    Returned object should include properties as:

    - **path** (*string*): Rewritten path, mandatory if no *code* provided
    - **query** (*array*): Rewritten query, if omitted original query keys
      are used
    - **headers** (*object*): Rewritten headers. If omitted, original
      request headers are used
    - **method** (*string*): Method of rewritten request. If omitted,
      original request method is used
    - **code** (*number*): Returned code. If provided, request is not rewritten
      and user immidiately receives response with the code
    - **body** (*string*): Body for POST/PUT requests, or for returning to user
      if *code* field provided. If POST/PUT request is being rewritten and no
      body returned by rewrite function, original request body is used

    **Example A**. Restricting access.

    .. code-block:: javascript

        function(req2) {
          var path = req2.path.slice(4),
            isWrite = /^(put|post|delete)$/i.test(req2.method),
            isFin = req2.userCtx.roles.indexOf("finance")>-1;
          if (path[0] == "finance" && isWrite && !isFin) {
            // Deny writes to  DB "finance" for users
            // having no "finance" role
            return {
              code: 403,
              body:JSON.stringify({
                error:"forbidden".
                reason:"You are not allowed to modify docs in this DB"
              })
            }
          }
          // Pass through all other requests
          return {path:"../../../"+path.join("/")}
        }

    **Example B**. Different replies for JSON and HTML requests.

    .. code-block:: javascript

        function(req2) {
          var path = req2.path.slice(4),
            h = headers,
            wantsJson = (h.Accept||"").indexOf("application/json")>-1,
            reply = {};
          if (!wantsJson) {
            // Here we should prepare reply object
            // for plain HTML pages
          } else {
            // Pass through JSON requests
            reply.path = "../../../"+path.join("/");
          }
          return reply;
        }

      The req2 object rewrites is called with is a slightly truncated version
      of req object, provided for list and update functions. Fields *info*,
      *uuid*, *id* and *form* are removed to speed up request processing.
      All other fields of the req object are in place.

Rewrite section is an array
^^^^^^^^^^^^^^^^^^^^^^^^^^^

    Each rule is an *object* with next structure:

    - **from** (*string*): The path rule used to bind current uri to the rule.
      It use pattern matching for that
    - **to** (*string*): Rule to rewrite an url. It can contain variables
      depending on  binding variables discovered during pattern matching and
      query args (url args and from the query member)
    - **method** (*string*): HTTP request method to bind the request method to
      the rule. Default is ``"*"``
    - **query** (*object*): Query args you want to define they can contain
      dynamic variable by binding the key

    The ``to``and ``from`` paths may contains string patterns with leading
    ``:`` or ``*`` characters.

    For example: ``/somepath/:var/*``

    - This path is converted in Erlang list by splitting ``/``
    - Each ``var`` are converted in atom
    - ``""`` are converted to ``''`` atom
    - The pattern matching is done by splitting ``/`` in request url in a list
      of token
    - A string pattern will match equal token
    - The star atom (``'*'`` in single quotes) will match any number of tokens,
      but may only be present as the last `pathterm` in a `pathspec`
    - If all tokens are matched and all `pathterms` are used, then the
      `pathspec` matches

    The pattern matching is done by first matching the HTTP request method to a
    rule. ``method`` is equal to ``"*"`` by default, and will match any HTTP
    method. It will then try to match the path to one rule. If no rule matches,
    then a :statuscode:`404` response returned.

    Once a rule is found we rewrite the request url using the ``to`` and
    ``query`` fields. The identified token are matched to the rule and will
    replace var. If ``'*'`` is found in the rule it will contain the remaining
    part if it exists.

    Examples:

    +-----------------------------------+----------+------------------+-------+
    |               Rule                |    Url   |  Rewrite to      | Tokens|
    +===================================+==========+==================+=======+
    | {"from": "/a",                    | /a       | /some            |       |
    |  "to": "/some"}                   |          |                  |       |
    +-----------------------------------+----------+------------------+-------+
    | {"from": "/a/\*",                 | /a/b/c   | /some/b/c        |       |
    |  "to": "/some/\*}                 |          |                  |       |
    +-----------------------------------+----------+------------------+-------+
    | {"from": "/a/b",                  | /a/b?k=v | /some?k=v        | k=v   |
    |  "to": "/some"}                   |          |                  |       |
    +-----------------------------------+----------+------------------+-------+
    | {"from": "/a/b",                  | /a/b     | /some/b?var=b    | var=b |
    |  "to": "/some/:var"}              |          |                  |       |
    +-----------------------------------+----------+------------------+-------+
    | {"from": "/a/:foo/",              | /a/b/c   | /some/b/c?foo=b  | foo=b |
    | "to": "/some/:foo/"}              |          |                  |       |
    +-----------------------------------+----------+------------------+-------+
    | {"from": "/a/:foo",               | /a/b     | /some/?k=b&foo=b | foo=b |
    |  "to": "/some",                   |          |                  |       |
    |  "query": { "k": ":foo" }}        |          |                  |       |
    +-----------------------------------+----------+------------------+-------+
    | {"from": "/a",                    | /a?foo=b | /some/?b&foo=b   | foo=b |
    |  "to": "/some/:foo"}              |          |                  |       |
    +-----------------------------------+----------+------------------+-------+

    Request method, header, query parameters, request payload and response body
    are depended on endpoint to which url will be rewritten.

    :param db: Database name
    :param ddoc: Design document name
    :param path: URL path to rewrite
