{% if not pillar['network']['common']%}
{% for v in pillar['network']['common'] %}
{{ v }}:
  network.routes:
    - name: {{ pillar['network']['common'][v]['interface'] }}
    - routes:
      - name: {{ v }}
  {% for k in pillar['network']['common'][v] %}
        {{ k }}: {{ pillar['network']['common'][v][k] }}
  {% endfor %}
{% endfor %}
{% endif %}

{% set id = grains['id'] %}
{% if pillar['network'][id] is defined %}
{% for i in pillar['network'][id] %}
{{ i }}:
  network.routes:
    - name: {{ pillar['network'][id][i]['interface'] }}
    - routes:
      - name: {{ i }}
  {% for j in pillar['network'][id][i] %}
        {{ j }}: {{ pillar['network'][id][i][j] }}
  {% endfor %}
{% endfor %}
{% endif %}
