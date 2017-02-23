
=======================
Django-Leonardo Formula
=======================

Sample pillar
=============

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            enabled: true
            workers: 3
            # disable strict host check on nginx proxy at app node
            dev: true
            bind:
              address: 0.0.0.0 # ${linux:network:fqdn}
              port: 9754
              protocol: tcp
            source:
              type: 'git'
              address: 'git@repo1.robotice.cz:python-apps/leonardo.git'
              rev: 'master'
            secret_key: 'y5m^_^ak6+5(f.m^_^ak6+5(f.m^_^ak6+5(f.'
            database:
              engine: 'postgresql'
              host: '127.0.0.1'
              name: 'leonardo'
              password: 'db-pwd'
              user: 'leonardo'
            mail:
              host: 'mail.domain.com'
              password: 'mail-pwd'
              user: 'mail-user'
            plugin:
              eshop: {}
              static: {}
              sentry: {}
              my_site:
                site: true
              blog:
                source:
                  engine: 'git'
                  address: 'git+https://github.com/django-leonardo/leonardo-module-blog.git#egg=leonardo_module_blog'

Site Name
---------

Without setting formula produce somethink like this ``Example app`` from your site name ``site_name``

.. code-block:: yaml

    leonardo:
      server:
        app:
          example_app:
            site_name: My awesome site

Site Language
-------------

.. code-block:: yaml

    leonardo:
      server:
        app:
          example_app:
            languages:
              en:
                default: true
              cs: {}
              de: {}

LDAP auth support
-----------------

.. code-block:: yaml

    leonardo:
      server:
        app:
          myapp:
            ldap:
              url: "ldaps://idm.example.com"
              binddn: "uid=apache,cn=users,cn=accounts,dc=example,dc=com"
              password: "secretpassword"
              basedn: "dc=example,dc=com"
              require_group: myapp-users
              flags_mapping:
                is_active: myapp-users
                is_staff: myapp-admins
                is_superuser: myapp-admins

This settings needs leonardo-auth-ldap installed.

Site Admins & Managers
----------------------

.. code-block:: yaml

    leonardo:
      server:
        app:
          example_app:
            admins:
              mail@majklk.cz:
                name: majklk 
              mail@newt.cz: {}
            managers:
              mail@majklk.cz:
                name: majklk 
              mail@newt.cz:
                name: newt 

Cache
-----

without setting cache we get default localhost memcache with per site prefix

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            cache:
              engine: 'memcached'
              host: '192.168.1.1'
              prefix: 'CACHE_EXAMPLEAPP'

Workers
-------

Leonardo uses Celery workers for long running backgrounds jobs which runs under supervisor.

Redis

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            worker: true
            broker:
              engine: redis
              host: 127.0.0.1
              port: 6379
              number: 0


AMQP

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            worker: true
            broker:
              engine: amqp
              host: 127.0.0.1
              port: 5672
              password: password
              user: example_app
              virtual_host: /


Sentry Exception Handling
-------------------------

.. code-block:: yaml

    leonardo:
      server:
        app:
          example_app:
            ...
            logging:
              engine: raven
              dsn: http://pub:private@sentry1.test.cz/2

Backup and Initial Data
-----------------------

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            backup: true
            initial_data:
              engine: backupninja
              source: backup.com
              host: web01.webapp.prd.dio.backup.com
              name: example_app

for reinit data do this::

    rm /root/postgresql/flags/leonardo_example_app-restored
    su postgres
    psql
    drop database leonardo_example_app;
    salt-call state.sls postgresql,leonardo

Gitversions

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            backup: true
            initial_data:
              engine: gitversions
              source: git@repo1.robotice.cz:majklk/backup-test.git

You also need django-gitversions installed.

Development Mode
----------------

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            development: true

Init your site
--------------

experimental feature for advanced users, which provides easy way to start your site without site repository ready yet

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            init: true

This parameter says, run ``makemigrations`` command before other management commands.

note: In default state ``makemigrations`` generates migrations into main leonardo module(repository).

Whatever
--------

Sometimes you need propagate plugin specifig config into your site, for this purpose we have simple but elegant solution for do this

.. code-block:: yaml

    leonardo:
      server:
        enabled: true
        app:
          example_app:
            plugin:
              eshop:
                config:
                  order: true

will be

.. code-block:: python

    ESHOP_CONFIG = {'order': True}

.. note::

    App.config will be rendered as python object in ``EXAMPLE_APP_CONFIG = {'app_config': True}``

Read more
=========

* https://launchpad.net/~tcpcloud
* https://github.com/django-leonardo/django-leonardo
* https://github.com/leonardo-modules/leonardo-auth-ldap
Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-leonardo/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-leonardo

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
