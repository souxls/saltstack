/etc/yum.repos.d/nginx.repo:
  file.managed:
    - source: salt://templates/yum.repo.d/nginx.repo
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: true
/etc/yum.repos.d/zabbix.repo:
  file.managed:
    - source: salt://templates/yum.repo.d/zabbix.repo
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - makedirs: true
