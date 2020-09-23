include:
{% for f in salt['file.find']('/srv/salt/pillar/mysql/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - mysql.{{ sls }}
  {% endif %}
{% endfor %}
