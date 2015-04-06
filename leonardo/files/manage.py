#!/usr/bin/env python

{%- set app = salt['pillar.get']('leonardo:server:app:'+app_name) %}
import os
import sys
from os.path import abspath, dirname, join, normpath

import django
from django.core.management import execute_from_command_line

path = '/srv/leonardo'
sys.path.append(
    join(path, 'sites', '{{ app_name }}', 'lib', 'python2.7', 'site-packages'))
sys.path.append(join(path, 'sites', '{{ app_name }}', 'leonardo'))
sys.path.append(join(path, 'sites', '{{ app_name }}', 'site'))


if __name__ == "__main__":
    os.environ['DJANGO_SETTINGS_MODULE'] = 'leonardo.settings'
    django.setup()
    execute_from_command_line(sys.argv)
