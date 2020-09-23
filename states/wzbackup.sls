wzBackup:
  file.managed:
    - name: /web/scripts/wzBackup.sh
    - source: salt://templates/scripts/wzBackup.sh
    - mode: 755

{% set id = grains['id'] %}
{% if pillar['wzbackup'][id] is defined %}
  {% for name in pillarr['wzbackup'][id] %}
    {% if pillarr['wzbackup'][id]['name']['host'] is defined %}
      {% set host = pillar['wzbackup'][id]['name']['host'] %}
    {% else %}
      {% set host = pillar['wzbackup']['common']['host'] %}
    {% endif %}
    {% if pillarr['wzbackup'][id]['name']['password'] is defined %}
      {% set password = pillar['wzbackup'][id]['name']['password'] %}
    {% else %}
      {% set password = pillar['wzbackup']['common']['password'] %}
    {% endif %}
    {% if pillarr['wzbackup'][id]['name']['exclude'] is defined %}
      {% set exclude = pillar['wzbackup'][id]['name']['exclude'] %}
    {% else %}
      {% set exclude = pillar['wzbackup']['common']['exclude'] %}
    {% endif %}

password file:
  file.managed:
    - name: /etc/rsyncd/rsyncd.pas
    - mode: 600
    - makedirs: True
    - contents: {{ password }}

www directory name:
  cron.present:
    - name: /web/scripts/wzBackup.sh -h {{ host }} -p /etc/rsyncd/rsyncd.pas --exclude='{{ exclude }}' {{ name }}
    - minute: 0
    - hour: 3
    - require:
      - file: wzBackup 
  {% endfor %}
{% else %}
  {% set name = pillar['wzbackup']['common']['name'] %}
  {% set host = pillar['wzbackup']['common']['host'] %}
  {% set password = pillar['wzbackup']['common']['password'] %}
  {% set exclude = pillar['wzbackup']['common']['exclude'] %}

password file:
  file.managed:
    - name: /etc/rsyncd/rsyncd.pas
    - mode: 600
    - makedirs: True
    - contents: {{ password }}

www directory:
  cron.present:
    - name: /web/scripts/wzBackup.sh -h {{ host }} -p /etc/rsyncd/rsyncd.pas --exclude='{{ exclude }}' {{ name }}
    - minute: 0
    - hour: 3
    - require:
      - file: wzBackup 
{% endif %}
