# -*- coding: utf-8 -*-

{%- set app = salt['pillar.get']('leonardo:server:app:'+app_name) %}

from __future__ import absolute_import

import sys
from os.path import join, dirname, abspath, normpath

DATABASES = {
    'default': {
        {%- if app.database.engine == 'mysql' %}
        'ENGINE': 'django.db.backends.mysql',
        'PORT': '3306',
        'OPTIONS': { 'init_command': 'SET storage_engine=INNODB,character_set_connection=utf8,collation_connection=utf8_unicode_ci', },
        {% elif app.database.engine == 'postgres' %}
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        {% elif app.database.engine == 'postgis' %}
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        {%- endif %}
        'HOST': '{{ app.database.host }}',
        'NAME': '{{ app.database.name }}',
        'PASSWORD': '{{ app.database.password }}',
        'USER': '{{ app.database.user }}'
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '{{ app.get("cache", {"host": "127.0.0.1"}).host }}:11211',
        'TIMEOUT': 120,
        'KEY_PREFIX': '{{ app.get("cache", {"prefix": "CACHE_"+ app_name|upper}).prefix }}'
    }
}

{%- if app.broker is defined and app.broker.engine == 'redis' %}
BROKER_URL = 'redis://{{ app.broker.host }}:{{ app.broker.port }}/{{ app.broker.number }}'
CELERY_DEFAULT_QUEUE = "{{ app_name }}"
{%- elif  app.broker is defined and app.broker.engine == 'amqp' %}
BROKER_URL = 'amqp://{{ app.broker.user }}:{{ app.broker.password }}@{{ app.broker.host }}:{{ app.broker.get("port",5672) }}/{{ app.broker.virtual_host }}'
{%- endif %}


SECRET_KEY = '{{ app.get('secret_key', '87941asd897897asd987') }}'

{%- if pillar.nginx is defined %}
{%- from "nginx/map.jinja" import server with context %}
{%- for site_name, site in server.get('site', {}).iteritems() %}
{%- if site.enabled and site.name == app_name and site.ssl is defined and site.ssl.enabled %}
{%- if (app.development is defined and not app.development) or (pillar.linux.system is defined and pillar.linux.system.get('environment', 'prd') != 'dev') %}
# Pass this header from the proxy after terminating the SSL,
# and don't forget to strip it from the client's request.
# For more information see:
# https://docs.djangoproject.com/en/1.8/ref/settings/#secure-proxy-ssl-header
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
# If Horizon is being served through SSL, then uncomment the following two
# settings to better secure the cookies from security exploits
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
# for sure
SECURE_SSL_REDIRECT = True
{%- endif %}
{%- endif %}
{%- endfor %}
{%- endif %}

{%- if app.secure is defined and app.secure and (app.development is defined and not app.development) or (pillar.linux.system is defined and pillar.linux.system.get('environment', 'prd') != 'dev') %}
# Pass this header from the proxy after terminating the SSL,
# and don't forget to strip it from the client's request.
# For more information see:
# https://docs.djangoproject.com/en/1.8/ref/settings/#secure-proxy-ssl-header
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
# If Horizon is being served through SSL, then uncomment the following two
# settings to better secure the cookies from security exploits
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
# for sure
SECURE_SSL_REDIRECT = True
{%- endif %}


{%- if app.mail.engine != "console" %}
{%- if app.mail.get('encryption', 'none') == 'tls' %}
EMAIL_USE_TLS = True
EMAIL_USE_SSL = False
{%- endif %}
{%- if app.mail.get('encryption', 'none') == 'ssl' %}
EMAIL_USE_SSL = True
{%- endif %}
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = '{{ app.mail.host }}'
EMAIL_HOST_USER = '{{ app.mail.user }}'
EMAIL_HOST_PASSWORD = '{{ app.mail.password }}'
EMAIL_PORT = {{ app.mail.get('port', '25') }}
{%- endif %}

{%- if app.development is defined %}
DEBUG = {{ app.get('development', True)|python }}
{%- elif pillar.linux.system is defined and pillar.linux.system.get('environment', 'prd') != 'dev' %}
DEBUG = False
{%- else %}
DEBUG = True
{%- endif %}

MEDIA_ROOT = '/srv/leonardo/sites/{{ app_name }}/media/'
STATIC_ROOT = '/srv/leonardo/sites/{{ app_name }}/static/'

ADMINS = (
{%- for email, user in app.get('admins', {}).iteritems() %}
    {%- if user.name is defined %}
    ('{{ user.name }}', '{{ email }}'),
    {%- else %}
    ('{{ email }}', '{{ email }}'),
    {%- endif %}
{%- endfor %}
)

{%- if app.managers is defined %}
ADMINS = (
{%- for email, user in app.get('managers', {}).iteritems() %}
    {%- if user.name is defined %}
    ('{{ user.name }}', '{{ email }}'),
    {%- else %}
    ('{{ email }}', '{{ email }}'),
    {%- endif %}
{%- endfor %}
)
{%- else %}
MANAGERS = ADMINS
{%- endif %}

SITE_NAME = '{{ app.get("site_name", app_name.replace('_', ' ')|capitalize) }}'
SITE_ID = 1

TIME_ZONE = '{{ pillar.linux.system.timezone }}'

{%- for lang_code, lang in app.get('languages', {'en': {'default': True}}).iteritems() %}
{%- if lang.default is defined and lang.default %}
LANGUAGE_CODE = '{{ lang_code|lower }}'
# only helper for jinja rendering
DEFAULT_LANG = [('{{ lang_code|lower }}', '{{ lang_code|upper }}')]
{%- endif %}
{%- endfor %}

LANGUAGES = DEFAULT_LANG + [
    {%- for lang_code, lang in app.get('languages', {'en': {'default': True}}).iteritems() %}
    {%- if not lang.default is defined or (lang.default is defined and not lang.default) %}
    ('{{ lang_code|lower }}', '{{ lang_code|upper }}'),
    {%- endif %}
    {%- endfor %}
]

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'root': {
        'level': 'WARNING',
        'handlers': ['file'],
    },
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        }
    },
    'formatters': {
        'verbose': {
            'format' : "[%(asctime)s] %(levelname)s [%(name)s:%(lineno)s] %(message)s",
            'datefmt' : "%d/%b/%Y %H:%M:%S"
        },
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
        'file': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': '/srv/leonardo/sites/{{ app_name }}/leonardo_server.log',
            'formatter': 'verbose'
        },
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler',
            'formatter': 'simple',
        },
    },
    'loggers': {
        'django.request': {
            'handlers': ['file'],
            'level': 'DEBUG',
            'propagate': True,
        },
    }
}

APPS = [
{%- for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
    {%- if plugin.get('add_to_apps', False) %}
    '{{ plugin_name }}',
    {%- endif %}
{%- endfor %}
]

{%- for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
{%- if plugin.config is defined %}
{{ plugin_name|upper }}_CONFIG = {{ plugin.config|python }}
{%- endif %}
{%- endfor %}

{%- if app.logging is defined and app.logging.engine in ["sentry", 'raven'] %}
RAVEN_CONFIG = {
    'dsn': '{{ app.logging.dsn }}',
}
{%- endif %}

LEONARDO_BOOTSTRAP_DIR = "/srv/leonardo/sites/{{ app_name }}/"

GITVERSIONS_ROOT_PATH = "/srv/leonardo/sites/{{ app_name }}/backup"
GITVERSIONS_AUTO_SYNC = False

# Dashboard custom fields
LEONARDO_CONF_SPEC = {
    'dashboard_menu': [],
    'dashboard_widgets_abailable': [],
    'dashboard_widgets': []
}
