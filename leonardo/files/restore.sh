#!/bin/sh

{%- from "leonardo/map.jinja" import server with context %}
{%- set app = salt['pillar.get']('leonardo:server:app:'+app_name) %}

{%- if app.initial_data is defined %}
scp -r backupninja@{{ app.initial_data.source }}:/srv/backupninja/{{ app.initial_data.host }}/srv/leonardo/sites/{{ app.initial_data.get('app', app_name) }}/media/media.0/* /srv/leonardo/sites/{{ app_name }}/media
cd /srv/leonardo/sites/{{ app_name }}
#chown leonardo:leonardo ./media/_cache -R
#chown leonardo:leonardo ./media/files -R
python manage.py thumbnail cleanup
python manage.py thumbnail clear
touch /root/leonardo/flags/{{ app_name }}-installed
{%- endif %}
