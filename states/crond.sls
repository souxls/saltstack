{% if not pillar['crond']['common']%}
{% for v in pillar['crond']['common'] %}
{{ v }}:
  cron.present:
    - user: root
  {% for k in pillar['crond']['common'][v] %}
    - {{ k }}: '{{ pillar['crond']['common'][v][k] }}'
  {% endfor %}
{% endfor %}
{% endif %}

{% set id = grains['id'] %}
{% if pillar['crond'][id] is defined %}
{% for i in pillar['crond'][id] %}
{{ i }}:
  cron.present:
    - user: root
  {% for j in pillar['crond'][id][i] %}
    - {{ j }}: '{{ pillar['crond'][id][i][j] }}'
  {% endfor %}
{% endfor %}
{% endif%}
