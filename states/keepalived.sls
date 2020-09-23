keepalived:
  pkg.installed:
    - fromrepo: base
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/keepalived/keepalived.conf

{% set lan = pillar['lan'] %}
{% set ip = ''.join(grains['ip4_interfaces'][lan][0]) %}
{% set router_id = pillar['keepalived'][ip]['router_id'] %}
{% set state  = pillar['keepalived'][ip]['state'] %}
{% set interface  = pillar['keepalived'][ip]['interface'] %}
{% set virtual_router_id  = pillar['keepalived'][ip]['virtual_router_id'] %}
{% set priority  = pillar['keepalived'][ip]['priority'] %}
{% set virtual_ipaddr  = pillar['keepalived'][ip]['virtual_ipaddress'].split(',') %}
/etc/keepalived/keepalived.conf:
  file.managed:
    - source: salt://templates/keepalived/keepalived.conf
    - user: root
    - group: root
    - template: jinja
    - require: 
      - pkg: keepalived
    - defaults:
      router_id: {{ router_id }}
      state: {{ state }}
      interface: {{ interface }}
      virtual_router_id: {{ virtual_router_id }}
      priority: {{ priority }}
      virtual_ipaddr: {{ virtual_ipaddr }}

/etc/keepalived/checknginx.sh:
  file.managed:
    - source: salt://templates/keepalived/checknginx.sh
    - user: root
    - group: root
    - mode: 755
