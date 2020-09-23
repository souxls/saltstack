flush filter:
  iptables.chain_present:
    - name: INPUT
    - table: filter

common state:
  iptables.insert:
    - position: 1
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: RELATED,ESTABLISHED
    - save: True

common icmp:
  iptables.insert:
    - position: 2
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - proto: icmp
    - save: True

common lo:
  iptables.insert:
    - position: 3
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - in-interface: lo
    - save: True

common lan:
  iptables.insert:
    - position: 4
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - source: '{{ pillar['source'] }}'
    - save: True

{% if not pillar['iptables']['common']%}
{% for v in pillar['iptables']['common'] %}
{{ v }}:
  iptables.insert:
    - position: 5
  {% for k in pillar['iptables']['common'][v] %}
    - {{ k }}: '{{ pillar['iptables']['common'][v][k] }}'
  {% endfor %}
{% endfor %}
{% endif %}

{% set id = grains['id'] %}
{% if pillar['iptables'][id] is defined %}
{% for i in pillar['iptables'][id] %}
{{ i }}:
  iptables.insert:
    - position: 5
  {% for j in pillar['iptables'][id][i] %}
    - {{ j }}: {{ pillar['iptables'][id][i][j] }}
  {% endfor %}
{% endfor %}
{% endif %}

common reject:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: REJECT
    - reject-with: icmp-host-prohibited
    - save: True

common forword:
  iptables.append:
    - table: filter
    - chain: FORWARD
    - jump: REJECT
    - reject-with: icmp-host-prohibited 
    - save: True

default to accept:
  iptables.set_policy:
    - table: filter
    - chain: INPUT
    - policy: ACCEPT
