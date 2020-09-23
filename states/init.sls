{% set lan = pillar['lan']%}
{% set ip = ''.join(grains['ip4_interfaces'][lan][0]) %}
