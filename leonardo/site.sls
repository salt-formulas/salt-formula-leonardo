
{%- from "leonardo/map.jinja" import server with context %}

{%- for app_name, app in server.get('app', {}).iteritems() %}

leonardo_source_{{ app_name }}:
  git.latest:
  - name: {{ app.source.address }}
  - target: /srv/leonardo/sites/{{ app_name }}/leonardo
  - rev: {{ app.source.get('rev', app.source.get('revision', 'master')) }}
  - require:
    - file: leonardo_{{ app_name }}_dirs

/srv/leonardo/sites/{{ app_name }}:
  virtualenv.manage:
  - requirements: /srv/leonardo/sites/{{ app_name }}/leonardo/requirements/default.txt
  - pip_download_cache: true
  - require:
    - pkg: leonardo_packages

{% for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
{% if not 'site' in plugin_name %}
{{ plugin_name }}_{{ app_name }}_req:
  pip.installed:
    {%- if 'source' in plugin and plugin.source.get('engine', 'git') == 'git' %}
    - editable: {{ plugin.source.address }}
    {%- else %}
    - requirements: /srv/leonardo/sites/{{ app_name }}/leonardo/requirements/extras/{{ plugin_name }}.txt
    {%- endif %}
    - bin_env: /srv/leonardo/sites/{{ app_name }}
    - download_cache: true
    - require:
      - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}
{% endfor %}

{% if app.database.engine == "postgresql" %}
psycopg2:
  pip.installed:
    - bin_env: /srv/leonardo/sites/{{ app_name }}
    - download_cache: true
    - require:
      - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}

leonardo_{{ app_name }}_dirs:
  file.directory:
  - names:
    - /srv/leonardo/sites/{{ app_name }}
    - /srv/leonardo/sites/{{ app_name }}/static
    - /srv/leonardo/sites/{{ app_name }}/media
    - /srv/leonardo/sites/{{ app_name }}/logs
    - /srv/leonardo/sites/{{ app_name }}/media/_cache
  - mode: 775
  - makedirs: true
  - require:
    - user: leonardo

{{ server.repository }}:leonardo-sites/{{ app_name }}.git:
  git.latest:
  - target: /srv/leonardo/sites/{{ app_name }}/site
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}
    - virtualenv: /srv/leonardo/sites/{{ app_name }}

/srv/leonardo/sites/{{ app_name }}/logs/access.log:
  file.managed:
  - mode: 666
  - require:
    - file: leonardo_{{ app_name }}_dirs

/srv/leonardo/sites/{{ app_name }}/logs/error.log:
  file.managed:
  - mode: 666
  - require:
    - file: leonardo_{{ app_name }}_dirs

/srv/leonardo/sites/{{ app_name }}/local_settings.py:
  file.managed:
  - source: salt://leonardo/files/settings.py
  - template: jinja
  - mode: 644
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: leonardo_{{ app_name }}_dirs

/srv/leonardo/sites/{{ app_name }}/bin/gunicorn_start:
  file.managed:
  - source: salt://leonardo/files/gunicorn_start
  - mode: 700
  - template: jinja
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: leonardo_{{ app_name }}_dirs

/srv/leonardo/sites/{{ app_name }}/manage.py:
  file.managed:
  - source: salt://leonardo/files/manage.py
  - template: jinja
  - mode: 755
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}/local_settings.py

leonardo_site_{{ app_name }}_wsgi:
  file.managed:
  - name: /srv/leonardo/sites/{{ app_name }}/wsgi.py
  - source: salt://leonardo/files/wsgi.py
  - mode: 755
  - template: jinja
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}/manage.py

sync_database_{{ app_name }}:
  cmd.run:
  - name: source /srv/leonardo/sites/{{ app_name }}/bin/activate; python manage.py syncdb --noinput
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - file: /srv/leonardo/sites/{{ app_name }}/manage.py

migrate_database_{{ app_name }}:
  cmd.run:
  - name: source /srv/leonardo/sites/{{ app_name }}/bin/activate; python manage.py migrate --noinput
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - cmd: sync_database_{{ app_name }}

collect_static_{{ app_name }}:
  cmd.run:
  - name: source /srv/leonardo/sites/{{ app_name }}/bin/activate; python manage.py collectstatic --noinput
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - cmd: sync_database_{{ app_name }}

sync_all_{{ app_name }}:
  cmd.run:
  - name: source /srv/leonardo/sites/{{ app_name }}/bin/activate; python manage.py sync_all
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - cmd: collect_static_{{ app_name }}

{%- if app.initial_data is defined %}

/root/leonardo/scripts/restore_{{ app_name }}.sh:
  file:
  - managed
  - source: salt://leonardo/files/restore.sh
  - mode: 700
  - template: jinja
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: /root/leonardo/scripts
    - file: /root/leonardo/flags
    - cmd: sync_database_{{ app_name }}

restore_leonardo_{{ app_name }}:
  cmd.run:
  - name: /root/leonardo/scripts/restore_{{ app_name }}.sh
  - unless: "[ -f /root/leonardo/flags/{{ app_name }}-installed ]"
  - cwd: /root
  - require:
    - file: /root/leonardo/scripts/restore_{{ app_name }}.sh

{%- endif %}

{# monkey path #}
chown_{{ app_name }}:
  cmd.run:
  - name: chown leonardo:leonardo ./* -R
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - cmd: sync_database_{{ app_name }}

{%- endfor %}