base:
  '*':
    - states.initpkg
    - states.yum
    - states.zabbix
    - states.snmpd
    - states.selinux
    - states.ssh
    - states.sysctl
    - states.crond
#    - states.network
    - states.iptables
    - states.ntp
    - states.rsyncd
  tomcat:
    - match: nodegroup
    - states.tomcat
  keepalived:
    - match: nodegroup
    - states.keepalived
#  nginx:
#    - match: nodegroup
#    - states.nginx
  nginxV4:
    - match: nodegroup
    - states.nginxV4
  php:
    - match: nodegroup
    - states.php
  mysql:
    - match: nodegroup
    - states.mysql
  wzbackup:
    - match: nodegroup
    - states.wzbackup
