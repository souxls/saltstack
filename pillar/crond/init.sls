include:
{% for f in salt['file.find']('/srv/salt/pillar/crond/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - crond.{{ sls }}
  {% endif %}
{% endfor %}
