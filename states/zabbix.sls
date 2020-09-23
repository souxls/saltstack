zabbix-agent:
  pkg.installed:
    - version: 2.2.13-1.el6
    - fromrepo: zabbix
    - skip_verify: true
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/zabbix/zabbix_agentd.conf


/etc/zabbix/zabbix_agentd.conf:
  file.managed:
    - source: salt://templates/zabbix/zabbix_agentd.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
      Server: {{ pillar['zabbix']['Server'] }}
      ServerActive: {{ pillar['zabbix']['ServerActive'] }}
