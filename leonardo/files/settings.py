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

SECRET_KEY = '{{ app.get('secret_key', '87941asd897897asd987') }}'

{%- if app.mail.engine != "console" %}
EMAIL_HOST = '{{ app.mail.host }}',
EMAIL_HOST_USER = '{{ app.mail.user }}',
EMAIL_HOST_PASSWORD = '{{ app.mail.password }}'
{%- endif %}

DEBUG = True
TEMPLATE_DEBUG = DEBUG

ADMINS = (
    ('Admin', 'mail@newt.cz'),
    ('Admin', 'mail@majklk.cz'),
)

MEDIA_ROOT = '/srv/leonardo/sites/{{ app_name }}/media/'
STATIC_ROOT = '/srv/leonardo/sites/{{ app_name }}/static/'

MANAGERS = ADMINS


SITE_NAME = '{{ app.get("site_name", app_name.replace('_', ' ')|capitalize) }}'
SITE_ID = 1

TIME_ZONE = '{{ pillar.linux.system.timezone }}'

LANGUAGE_CODE = '{{  app.get('language', 'en') }}'

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
            'handlers': ['mail_admins', 'file'],
            'level': 'DEBUG',
            'propagate': True,
        },
    }
}

APPS = [
{%- for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
    '{{ plugin_name }}',
{%- endfor %}
]

# SUPPORT FOR SPECIFIC APP CONFIG
{%- for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
{%- if plugin.config is defined %}
{{ plugin_name|upper }}_CONFIG = {{ plugin.config|python }}
{%- endif %}
{%- endfor %}
