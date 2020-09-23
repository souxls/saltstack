/etc/snmp/snmpd.conf:
  file.managed:
    - user: root
    - source: salt://templates/snmpd/snmpd.conf
    - template: jinja
