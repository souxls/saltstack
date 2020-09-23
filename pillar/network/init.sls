include:
{% for f in salt['file.find']('/srv/salt/pillar/network/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - network.{{ sls }}
  {% endif %}
{% endfor %}
