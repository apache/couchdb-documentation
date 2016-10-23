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

.. _install/unix:

=================================
Installation on Unix-like systems
=================================

A high-level guide to Unix-like systems, including Mac OS X and Ubuntu.

This document as well as the INSTALL.Unix document in the official
release are the canonical sources of installation information. However, many
systems have gotchas that you need to be aware of. In addition, dependencies
frequently change as distributions update their archives.

.. _install/unix/dependencies:

Dependencies
============

You should have the following installed:

* `Erlang OTP (>=R16B03, =<19.x) <http://erlang.org/>`_
* `ICU                          <http://icu-project.org/>`_
* `OpenSSL                      <http://www.openssl.org/>`_
* `Mozilla SpiderMonkey (1.8.5) <http://www.mozilla.org/js/spidermonkey/>`_
* `GNU Make                     <http://www.gnu.org/software/make/>`_
* `GNU Compiler Collection      <http://gcc.gnu.org/>`_
* `libcurl                      <http://curl.haxx.se/libcurl/>`_
* `help2man                     <http://www.gnu.org/s/help2man/>`_
* `Python (>=2.7) for docs      <http://python.org/>`_
* `Python Sphinx (>=1.1.3)      <http://pypi.python.org/pypi/Sphinx>`_

It is recommended that you install Erlang OTP R16B03-1 or above where possible.
You will only need libcurl if you plan to run the JavaScript test suite. And
help2man is only need if you plan on installing the CouchDB man pages.
Python and Sphinx are only required for building the online documentation.
Documentation build can be disabled by adding the ``--disable-docs`` flag to
the ``configure`` script.

.. seealso::

    * `Installing CouchDB <https://cwiki.apache.org/confluence/display/COUCHDB/Installing+CouchDB>`_

Debian-based Systems
--------------------

You can install the dependencies by running::

    sudo apt-get --no-install-recommends -y install \
        build-essential pkg-config erlang \
        libicu-dev libmozjs185-dev libcurl4-openssl-dev

Be sure to update the version numbers to match your system's available
packages.

RedHat-based (Fedora, Centos, RHEL) Systems
-------------------------------------------

You can install the dependencies by running::

    sudo yum install autoconf autoconf-archive automake \
        curl-devel erlang-asn1 erlang-erts erlang-eunit \
        erlang-os_mon erlang-xmerl help2man \
        js-devel-1.8.5 libicu-devel libtool perl-Test-Harness

While CouchDB builds against the default js-devel-1.7.0 included in some
distributions, it's recommended to use a more recent js-devel-1.8.5.

Mac OS X
--------

Follow :ref:`install/mac/homebrew` reference for Mac App installation.

If you are installing from source, you will need to install the Command
Line Tools::

    xcode-select --install

You can then install the other dependencies by running::

    brew install autoconf autoconf-archive automake libtool \
        erlang icu4c spidermonkey curl pkg-config

You will need `Homebrew` installed to use the ``brew`` command.

Some versions of Mac OS X ship a problematic OpenSSL library. If
you're experiencing troubles with CouchDB crashing intermittently with
a segmentation fault or a bus error, you will need to install your own
version of OpenSSL. See the wiki, mentioned above, for more information.

.. seealso::

    * `Homebrew <http://mxcl.github.com/homebrew/>`_

FreeBSD
-------

FreeBSD requires the use of GNU Make. Where ``make`` is specified in this
documentation, substitute ``gmake``.

You can install this by running::

    pkg install gmake

Installing
==========

Once you have satisfied the dependencies you should run::

    ./configure

If you wish to customize the installation, pass ``--help`` to this script.

If everything was successful you should see the following message::

    You have configured Apache CouchDB, time to relax.

Relax.

To build CouchDB you should run::

    make release

Try ``gmake`` if ``make`` is giving you any problems.

If include paths or other compiler options must be specified, they can be passed to rebar, which compiles CouchDB, with the ERL_CFLAGS environment variable. Likewise, options may be passed to the linker with the ERL_LDFLAGS environment variable::

    make release ERL_CFLAGS="-I/usr/local/include/js -I/usr/local/lib/erlang/usr/include"

If everything was successful you should see the following message::

    ... done
    You can now copy the rel/couchdb directory anywhere on your system.
    Start CouchDB with ./bin/couchdb from within that directory.

Relax.

Note: a fully-fledged ``./configure`` with the usual GNU Autotools options
for package managers and a corresponding ``make install`` are in
development, but not part of the 2.0.0 release.

.. _install/unix/security:

User Registration and Security
==============================

For OS X, in the steps below, substitute ``/Users/couchdb`` for
``/home/couchdb``.

You should create a special ``couchdb`` user for CouchDB.

On many Unix-like systems you can run::

    adduser --system \
            --shell /bin/bash \
            --group --gecos \
            "CouchDB Administrator" couchdb

On Mac OS X you can use the Workgroup Manager to create users up to version
10.9, and dscl or sysadminctl after version 10.9. Search Apple's support
site to find the documentation appropriate for your system. As of recent
versions of OS X, this functionality is also included in Server.app,
available through the App Store only as part of OS X Server.

You must make sure that the user has a working POSIX shell and a writable
home directory.

You can test this by:

* Trying to log in as the ``couchdb`` user
* Running ``pwd`` and checking the present working directory

As a recommendation, copy the ``rel/couchdb`` directory into
``/home/couchdb`` or ``/Users/couchdb``.

Ex: copy the built couchdb release to the new user's home directory::

    cp -R /path/to/couchdb/rel/couchdb /home/couchdb

Change the ownership of the CouchDB directories by running::

    chown -R couchdb:couchdb /home/couchdb

Change the permission of the CouchDB directories by running::

    find /home/couchdb -type d -exec chmod 0770 {} \;

Update the permissions for your ini files::

    chmod 0644 /home/couchdb/etc/*

First Run
=========

You can start the CouchDB server by running::

    sudo -i -u couchdb /home/couchdb/bin/couchdb

This uses the ``sudo`` command to run the ``couchdb`` command as the
``couchdb`` user.

When CouchDB starts it should eventually display following messages::

    {database_does_not_exist,[{mem3_shards,load_shards_from_db,"_users" ...

Don't be afraid, we will fix this in a moment.

To check that everything has worked, point your web browser to::

    http://127.0.0.1:5984/_utils/index.html

From here you should verify your installation by pointing your web browser to::

    http://localhost:5984/_utils/index.html#verifyinstall

Finally, to configure your cluster see :ref:`cluster/setup/wizard`.

Running as a Daemon
===================

CouchDB no longer ships with any daemonization scripts.

The CouchDB team recommends `runit <http://smarden.org/runit/>`_ to
run CouchDB persistently and reliably. According to official site:

    *runit* is a cross-platform Unix init scheme with service supervision,
    a replacement for sysvinit, and other init schemes. It runs on
    GNU/Linux, \*BSD, MacOSX, Solaris, and can easily be adapted to
    other Unix operating systems.

Configuration of runit is straightforward; if you have questions, contact
the CouchDB `user mailing list <http://mail-archives.apache.org/mod_mbox/couchdb-user/>`_
or `IRC-channel #couchdb <http://webchat.freenode.net/?channels=#couchdb>`_
in FreeNode network.

Let's consider configuring runit on Ubuntu 16.04. The following
steps should be considered only as an example. Details will vary
by operating system and distribution. Check your system's package
management tools for specifics.

Install runit::

    sudo apt-get install runit

Create a directory where logs will be written::

    sudo mkdir /var/log/couchdb
    sudo chown couchdb:couchdb /var/log/couchdb

Create directories that will contain runit configuration for CouchDB::

    sudo mkdir /etc/sv/couchdb
    sudo mkdir /etc/sv/couchdb/log

Create /etc/sv/couchdb/log/run script::

    #!/bin/sh
    exec svlogd -tt /var/log/couchdb

Basically it determines where and how exactly logs will be written.
See ``man svlogd`` for more details.

Create /etc/sv/couchdb/run::

    #!/bin/sh
    export HOME=/home/couchdb
    exec 2>&1
    exec chpst -u couchdb /home/couchdb/bin/couchdb

This script determines how exactly CouchDB will be launched.
Feel free to add any additional arguments and environment
variables here if necessary.

Make scripts executable::

    sudo chmod u+x /etc/sv/couchdb/log/run
    sudo chmod u+x /etc/sv/couchdb/run

Then run::

    sudo ln -s /etc/sv/couchdb/ /etc/service/couchdb

In a few seconds runit will discover a new symlink and start CouchDB.
You can control CouchDB service like this::

    sudo sv status couchdb
    sudo sv stop couchdb
    sudo sv start couchdb

Naturally now CouchDB will start automatically shortly after system starts.

You can also configure systemd, launchd or SysV-init daemons to launch
CouchDB and keep it running using standard configuration files. Consult
your system documentation for more information.
