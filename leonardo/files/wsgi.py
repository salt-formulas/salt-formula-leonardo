#!/usr/bin/env python

{%- set app = salt['pillar.get']('leonardo:server:app:'+app_name) %}

import os
import sys
from os.path import abspath, dirname, join, normpath

import django
import django.core.handlers.wsgi
from django.core.management import execute_from_command_line

path = '/srv/leonardo'
sys.path.append(
    join(path, 'sites', '{{ app_name }}', 'lib', 'python2.7', 'site-packages'))
{%- if app.source is defined and app.source.engine == 'git' %}
sys.path.append(join(path, 'sites', '{{ app_name }}', 'leonardo'))
{%- endif %}
sys.path.append(join(path, 'sites', '{{ app_name }}', 'site'))

os.environ['DJANGO_SETTINGS_MODULE'] = 'leonardo.settings'
django.setup()


application = django.core.handlers.wsgi.WSGIHandler()
