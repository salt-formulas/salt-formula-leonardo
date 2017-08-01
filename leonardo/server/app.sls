{%- from "leonardo/map.jinja" import server with context %}
{%- if server.enabled %}

{%- if salt['pillar.get']('app_name', False) %}

{%- set app_name = salt['pillar.get']('app_name') %}
{%- set app = salt['pillar.get']('leonardo:server:app:'+app_name) %}
{% include "leonardo/server/_app.sls" %}

{%- else %}

{%- for app_name, app in server.get('app', {}).iteritems() %}
{% include "leonardo/server/_app.sls" %}
{%- endfor %}

{%- endif %}

{%- endif %}
