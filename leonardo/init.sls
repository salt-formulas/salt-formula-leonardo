
include:
{% if pillar.leonardo is defined %}
{% if pillar.leonardo.server is defined %}
- leonardo.server
{% endif %}
{% endif %}
