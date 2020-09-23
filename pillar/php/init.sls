include:
{% for f in salt['file.find']('/srv/salt/pillar/php/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - php.{{ sls }}
  {% endif %}
{% endfor %}

