/etc/ssh/sshd_config:
  file.managed:
    - user: root
    - source: salt://templates/ssh/sshd_config
sshkeys:
  ssh_auth.present:
    - user: root
    - source: salt://templates/ssh/sshkeys.pub
    - config: /root/.ssh/authorized_keys
