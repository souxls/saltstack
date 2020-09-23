include:
{% for f in salt['file.find']('/srv/salt/pillar/iptables/', name='*.sls', print='name') %}
  {% if f != 'init.sls' %}
    {% set sls = f.split('.')[0] %}
  - iptables.{{ sls }}
  {% endif %}
{% endfor %}
