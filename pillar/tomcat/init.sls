include:
{% for f in salt['file.find']('/srv/salt/pillar/tomcat/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - tomcat.{{ sls }}
  {% endif %}
{% endfor %}
