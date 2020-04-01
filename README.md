# CouchDB Documentation [![Build Status](https://travis-ci.org/apache/couchdb-documentation.svg?branch=master)](https://travis-ci.org/apache/couchdb-documentation)

This repository contains the Sphinx source for Apache CouchDB's documentation.
You can view the latest rendered build of this content at:

    http://docs.couchdb.org/en/latest

# Getting Started

## Prerequisites

- Python 3.x
- Pip

### Preparing Prerequisites using [asdf](https://asdf-vm.com/#/)

```sh
$ asdf plugin add python
$ asdf install python 3.8.2
$ pip pip install -r requirements.txt
$ asdf reshim python
```
### Preparing Prerequisites having Python/Pip already installed

```sh
$ pip install -r requirements.txt
```

## Building the Repo

```sh
$ make html # builds the docs
$ make check # syntax checks the docs
```

# Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project.

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md


