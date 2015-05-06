
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

in default state formula produce somethink like this ``Example app`` for custom name set ``site_name``

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
            language: 'cz'

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

* https://github.com/django-leonardo/django-leonardo