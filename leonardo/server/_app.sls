
{%- if app.bind is defined and app.bind.port is defined %}
{%- set app_bind_port = app.bind.port %}
{%- else %}
{%- set app_bind_port = 8000 + loop.index %}
{%- endif %}

{%- set index_url = app.source.get('address', 'http://pypi.python.org/simple/') %}

{%- if app.source is defined and app.source.engine == 'git' %}
leonardo_source_{{ app_name }}:
  git.latest:
  - name: {{ app.source.address }}
  - target: /srv/leonardo/sites/{{ app_name }}/leonardo
  - rev: {{ app.source.get('rev', app.source.get('revision', 'master')) }}
  - force_reset: True
  - require:
    - file: leonardo_{{ app_name }}_dirs
{% elif app.source is defined and app.source.engine == 'pip' %}
leonardo_{{ app_name }}:
  pip.installed:
  {%- if app.source.address is defined %}
  - index_url: {{ index_url }}
  - trusted_host: {{ index_url.replace('https://', '').replace('/simple/', '') }}
  {%- endif %}
  - process_dependency_links: True
  - pre_releases: True
  - name: django-leonardo
  - bin_env: /srv/leonardo/sites/{{ app_name }}
  - require:
    - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}

/srv/leonardo/sites/{{ app_name }}:
  virtualenv.manage:
  {%- if app.source is defined and app.source.engine == 'git' %}
  - requirements: /srv/leonardo/sites/{{ app_name }}/leonardo/requirements/default.txt
  {%- else %}
  - requirements: salt://leonardo/files/requirements.txt
  {%- endif %}
  - require:
    - pkg: leonardo_packages
    {% if app.source is defined and app.source.engine == 'git' %}
    - git: leonardo_source_{{ app_name }}
    {% endif %}

pip_{{ app_name }}_extra:
  pip.installed:
  - requirements: salt://leonardo/files/requirements.txt
  - bin_env: /srv/leonardo/sites/{{ app_name }}
  - process_dependency_links: True
  - require:
    - virtualenv: /srv/leonardo/sites/{{ app_name }}

{% for plugin_name, plugin in app.get('plugin', {}).iteritems() %}
{% if not plugin.get('site', false) %}
{{ plugin_name }}_{{ app_name }}_req:
  pip.installed:
  {%- if 'source' in plugin and plugin.source.get('engine', 'git') == 'git' %}
  - editable: {{ plugin.source.address }}
  {%- elif 'source' in plugin and plugin.source.engine == 'pip' %}
  - name: {{ plugin_name }} {%- if plugin.version is defined %}=={{ plugin.version }}{% endif %}
  {%- if plugin.source.address is defined %}
  - index_url: {{ plugin.source.get('address', 'http://pypi.python.org') }}
  - trusted_host: {{ index_url.replace('https://', '').replace('/simple/', '') }}
  {%- endif %}
  {%- if not plugin.version is defined %}
  - pre_releases: True
  {%- endif %}
  {%- else %}
  {%- if app.source is defined and app.source.engine == 'git' %}
  - requirements: /srv/leonardo/sites/{{ app_name }}/leonardo/requirements/extras/{{ plugin_name }}.txt
  {%- else %}
  - name: {{ plugin_name }}
  {%- endif %}
  {%- endif %}
  - bin_env: /srv/leonardo/sites/{{ app_name }}
  - exists_action: w
  - process_dependency_links: True
  - require:
    - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}
{% endfor %}

{% if app.logging is defined %}
logging_{{ app_name }}_req:
  pip.installed:
  {%- if app.source is defined and app.source.engine == 'git' %}
  - requirements: /srv/leonardo/sites/{{ app_name }}/leonardo/requirements/extras/{{ app.logging.engine }}.txt
  {%- else %}
  - requirements: /srv/leonardo/sites/{{ app_name }}/src/leonardo/requirements/extras/{{ app.logging.engine }}.txt
  {%- endif %}
  - bin_env: /srv/leonardo/sites/{{ app_name }}
  - require:
    - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}

{% if app.database.engine in ["postgresql", "postgres", 'postgis'] %}
psycopg2_{{ app_name }}:
  pip.installed:
    - name: psycopg2
    - bin_env: /srv/leonardo/sites/{{ app_name }}
    - require:
      - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}

{% if app.worker is defined and app.worker %}
redis_{{ app_name }}:
  pip.installed:
    - name: redis
    - bin_env: /srv/leonardo/sites/{{ app_name }}
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
    - /var/log/leonardo
  - mode: 775
  - makedirs: true
  - group: leonardo
  - user: leonardo
  - require:
    - user: leonardo

{%- if not app.get('site_source', false) %}
{{ server.repository }}:leonardo-sites/{{ app_name|replace('_', '-') }}-site.git:
  git.latest:
  - target: /srv/leonardo/sites/{{ app_name }}/site
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}
    - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% else %}
leonardo_{{ app_name }}_site_source:
  git.latest:
  - name: {{ app.site_source.address }}
  - rev: {{ app.site_source.get('rev', 'master') }}
  - target: /srv/leonardo/sites/{{ app_name }}/site
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}
    - virtualenv: /srv/leonardo/sites/{{ app_name }}
{% endif %}

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
    port: {{ app_bind_port }}
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
  {%- if app.server_engine is defined and app.server_engine == "daphne" %}
  - name: /srv/leonardo/sites/{{ app_name }}/asgi.py
  - source: salt://leonardo/files/asgi.py
  {%- else %}
  - name: /srv/leonardo/sites/{{ app_name }}/wsgi.py
  - source: salt://leonardo/files/wsgi.py
  {%- endif %}
  - mode: 755
  - template: jinja
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}/manage.py

{% do app.get('admins', {}).update(app.get('managers', {})) %}

leonardo_site_{{ app_name }}_bootstrap:
  file.managed:
  - name: /srv/leonardo/sites/{{ app_name }}/demo.yaml
  - source: salt://leonardo/files/bootstrap.yml
  - mode: 755
  - template: jinja
  - defaults:
    users: {{ app.get('admins', {}) }}
  - require:
    - file: /srv/leonardo/sites/{{ app_name }}

{%- if app.get('init', false) %}
makemigrations_{{ app_name }}:
  cmd.run:
  - names:
    - source /srv/leonardo/sites/{{ app_name }}/bin/activate; /srv/leonardo/sites/{{ app_name }}/bin/python manage.py makemigrations --merge --noinput
    - touch /root/leonardo/flags/{{ app_name }}-installed
  - unless: "[ -f /root/leonardo/flags/{{ app_name }}-installed ]"
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - file: /srv/leonardo/sites/{{ app_name }}/local_settings.py

{% for username, user in app.get('admins', {}).iteritems() %}
{{ username }}_{{ app_name }}_req:
  module.run:
  - name: django.createsuperuser
  - settings_module: leonardo.settings
  - username: {{ username }}
  - email: {{ username }}
  - bin_env: /srv/leonardo/sites/{{ app_name }}
  - pythonpath: "/srv/leonardo/sites/{{ app_name }}/leonardo:/srv/leonardo/sites/{{ app_name }}"
  - require:
    - cmd: sync_all_{{ app_name }}
{% endfor %}

{%- endif %}

migrate_database_{{ app_name }}:
  cmd.run:
  - name: source /srv/leonardo/sites/{{ app_name }}/bin/activate; /srv/leonardo/sites/{{ app_name }}/bin/python manage.py migrate --noinput
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    {%- if app.get('init', false) %}
    - cmd: makemigrations_{{ app_name }}
    {%- endif %}
    - file: leonardo_{{ app_name }}_dirs
    - file: /srv/leonardo/sites/{{ app_name }}/local_settings.py

sync_all_{{ app_name }}:
  cmd.run:
  - name: 'source /srv/leonardo/sites/{{ app_name }}/bin/activate;rm -r /srv/leonardo/sites/{{ app_name }}/static;/srv/leonardo/sites/{{ app_name }}/bin/python manage.py sync_all -f;chown leonardo:leonardo ./* -R'
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
    - cmd: migrate_database_{{ app_name }}

{%- if app.initial_data is defined %}

{%- if app.initial_data.engine is defined and app.initial_data.engine == "gitversions" %}

restore_leonardo_{{ app_name }}:
  cmd.run:
  - name: source /srv/leonardo/sites/{{ app_name }}/bin/activate; python manage.py gitrestore --url={{ app.initial_data.source }} && touch /root/leonardo/flags/{{ app_name }}-restored
  - unless: "test -e /root/leonardo/flags/{{ app_name }}-restored"
  - cwd: /root
  - require:
    - file: /root/leonardo/flags
    - cmd: sync_all_{{ app_name }}

{%- else %}

/root/leonardo/scripts/restore_{{ app_name }}.sh:
  file:
  - managed
  - source: salt://leonardo/files/restore_{{ app.initial_data.engine }}.sh
  - mode: 700
  - template: jinja
  - defaults:
    app_name: "{{ app_name }}"
  - require:
    - file: /root/leonardo/scripts
    - file: /root/leonardo/flags

restore_leonardo_{{ app_name }}:
  cmd.run:
  - names:
    - /root/leonardo/scripts/restore_{{ app_name }}.sh && touch /root/leonardo/flags/{{ app_name }}-restored
  - unless: "test -e /root/leonardo/flags/{{ app_name }}-restored"
  - cwd: /root
  - require:
    - file: /root/leonardo/scripts/restore_{{ app_name }}.sh

{%- endif %}

{%- endif %}

{# monkey path #}
chown_{{ app_name }}:
  cmd.run:
  - name: chown leonardo:leonardo ./* -R
  - cwd: /srv/leonardo/sites/{{ app_name }}
  - require:
    - file: leonardo_{{ app_name }}_dirs
