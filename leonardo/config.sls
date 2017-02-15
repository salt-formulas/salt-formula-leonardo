
{%- from "leonardo/map.jinja" import server with context %}

{%- set has_os_config = True %}

{%- for app_name, app in server.get('app', {}).iteritems() %}
{%- if not app.service_endpoint is defined %}
{%- set has_os_config = False %}
{%- endif %}
{%- endfor %}

{%- if has_os_config %}

leonardo_os_config_dirs:
  file.directory:
  - names:
    - /etc/openstack
  - makedirs: true
  - group: leonardo
  - user: leonardo

/etc/openstack/clouds.yaml:
  file.managed:
  - source: salt://leonardo/files/openstack_clouds.yaml
  - template: jinja
  - group: leonardo
  - user: leonardo
  - require:
    - file: leonardo_os_config_dirs

{%- endif %}

