include:
{% for f in salt['file.find']('/srv/salt/pillar/rsyncd/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - rsyncd.{{ sls }}
  {% endif %}
{% endfor %}

