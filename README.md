
# Django-Leonardo Formula

## Sample pillar

    leonardo:
      server:
        enabled: true
        secret_key: 'y5m^_^ak6+5(f.m^_^ak6+5(f.m^_^ak6+5(f.'
        source:
          type: 'git'
          address: 'git@repo1.robotice.cz:python-apps/leonardo.git'
          rev: 'master'
        app:
          example_app:
            config:
              app_config: true
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
              cms: {}
              web: {}
              blog: {}

.. note::

    App.config will be rendered as python object in ``EXAMPLE_APP_CONFIG = {'app_config': True}``

## Read more

* ...