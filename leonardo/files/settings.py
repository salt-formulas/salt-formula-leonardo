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
        {% else %}
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
        'LOCATION': '{{ app.cache.host }}:11211',
        'TIMEOUT': 120,
        'KEY_PREFIX': '{{ app.cache.prefix }}'
    }
}
{% if app.secret_key is defined %}
SECRET_KEY = '{{ app.secret_key }}'
{% endif %}

SITE_BRANDING = '{{ app.get('branding', 'leonardo') }}'

{%- if app.mail.engine != "console" %}
EMAIL_HOST = '{{ app.mail.host }}',
EMAIL_HOST_USER = '{{ app.mail.user }}',
EMAIL_HOST_PASSWORD = '{{ app.mail.password }}'
{%- endif %}

{%- if app.robotice_api is defined %}
ROBOTICE_HOST = '{{ app.robotice_api.host }}'
ROBOTICE_PORT = '{{ app.robotice_api.port }}'
{%- endif %}


DEBUG = True
TEMPLATE_DEBUG = DEBUG

ADMINS = (
    ('Admin', 'mail@newt.cz'),
)

MEDIA_ROOT = '/srv/leonardo/sites/{{ app_name }}/media/'
STATIC_ROOT = '/srv/leonardo/sites/{{ app_name }}/static/'

MANAGERS = ADMINS

SITE_ID = 1
SITE_NAME = 'leonardo'

TIME_ZONE = '{{ pillar.linux.system.timezone }}'

LANGUAGE_CODE = 'en'

APPS = [
{%- for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
    '{{ plugin_name }}',
{%- endfor %}
]

# SUPPORT FOR SPECIFIC APP CONFIG
{%- for plugin_name, plugin in app.plugin.iteritems() %}
{%- if plugin.config is defined %}
{{ plugin_name|upper }}_CONFIG = {{ plugin.config|python }}
{%- endif %}
{%- endfor %}

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
