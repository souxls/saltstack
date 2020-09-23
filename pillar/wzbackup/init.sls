include:
{% for f in salt['file.find']('/srv/salt/pillar/wzbackup/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - wzbackup.{{ sls }}
  {% endif %}
{% endfor %}
