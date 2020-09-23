base:
  '*':
    - snmp
    - crond
    - network
    - iptables
    - ntp
    - zabbix
    - rsyncd
  keepalived:
    - match: nodegroup
    - keepalived
  nginx:
    - match: nodegroup
    - nginx
  nginxV4:
    - match: nodegroup
    - nginx
  tomcat:
    - match: nodegroup
    - tomcat
  mysql:
    - match: nodegroup
    - mysql
  wzbackup:
    - match: nodegroup
    - wzbackup
