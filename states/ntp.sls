{% set server = pillar['ntp']['server'] %}
echo 'server {{ server }}' >>/etc/ntp.conf && /etc/init.d/ntpd restart:
  cmd.run:
    - unless: grep "{{ server }}" /etc/ntp.conf
