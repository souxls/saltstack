/etc/selinux/config:
  file.managed:
    - source: salt://templates/selinux/config
