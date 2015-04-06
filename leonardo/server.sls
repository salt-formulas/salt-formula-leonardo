
{%- from "leonardo/map.jinja" import server with context %}

{%- if server.enabled %}

include:
- git

leonardo_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

leonardo:
  user.present:
  - name: leonardo
  - shell: /bin/bash
  - home: /srv/leonardo

/root/leonardo/scripts:
  file.directory:
  - user: root
  - group: root
  - mode: 700
  - makedirs: true

/root/leonardo/flags:
  file:
  - directory
  - user: root
  - group: root
  - mode: 700
  - makedirs: true

{%- endif %}
