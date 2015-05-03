
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
            config:
              app_config: true
            secret_key: 'y5m^_^ak6+5(f.m^_^ak6+5(f.m^_^ak6+5(f.'
            cache:
              engine: 'memcached'
              host: '127.0.0.1'
              prefix: 'CACHE_leonardo'
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

.. note::

    App.config will be rendered as python object in ``EXAMPLE_APP_CONFIG = {'app_config': True}``

Read more
=========

* https://github.com/django-leonardo/django-leonardo