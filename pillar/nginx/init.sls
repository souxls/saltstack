include:
{% for f in salt['file.find']('/srv/salt/pillar/nginx/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - nginx.{{ sls }}
  {% endif %}
{% endfor %}
