
include:
{% if pillar.leonardo.server is defined %}
- leonardo.server
- leonardo.site
- leonardo.config
{% endif %}
