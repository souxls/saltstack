libaio-devel:
  pkg.installed

mysql:
  user.present:
    - name: mysql
    - shell: /sbin/nologin
    - createhome: False

{% set lan = pillar['lan'] %}
{% set ip = ''.join(grains['ip4_interfaces'][lan][0]) %}
{% if pillar['mysql'][ip] is defined %}
  {% for server in pillar['mysql'][ip] %}
    {% if pillar['mysql'][ip][server]['version'] is defined %}
      {% set version = pillar['mysql'][ip][server]['version'] %}
    {% else %}
      {% set version = pillar['mysql']['common']['version'] %}
    {% endif %}
    {% if pillar['mysql'][ip][server]['id'] is defined %}
      {% set id = pillar['mysql'][ip][server]['id'] %}
    {% else %}
      {% set id = pillar['mysql']['common']['id'] %}
    {% endif %}
    {% if pillar['mysql'][ip][server]['port'] is defined %}
      {% set port = pillar['mysql'][ip][server]['port'] %}
    {% else %}
      {% set port = pillar['mysql']['common']['port'] %}
    {% endif %}
    {% if pillar['mysql'][ip][server]['dest'] is defined %}
      {% set dest = pillar['mysql'][ip][server]['dest'] %}
    {% else %}
      {% set dest = pillar['mysql']['common']['dest'] %}
  {% endif %}
  {% set ver = version[:18] %}

{{ server }}_{{ version }}.tar.gz:
  archive.extracted:
    - name: /opt/
    - source:
      - salt://templates/mysql/{{ version }}.tar.gz
    - archive_format: tar
    - tar_options: z
    - if_missing: /opt/{{ version }}

{{ server }}_mysql_node_install.pl:
  file.managed:
    - name: /opt/scripts/mysql_node_install.pl
    - source: salt://templates/mysql/mysql_node_install.pl
    - mode: 755
    - makedirs: True

{{ server }}_mysql_directory:
  file.directory:
    - name: {{ dest }}/mysql
    - makedirs: True

{{ server }}_mysql_install:
  cmd.run:
    - name: perl /opt/scripts/mysql_node_install.pl --port={{ port }} --base=/opt/{{version }} --dest='{{ dest }}' --id={{ id }}
    - unless: ls {{ dest }}/mysql/node{{ port }}
    - require:
      - archive: {{ server }}_{{ version }}.tar.gz
      - file: {{ server }}_mysql_node_install.pl
      - file: {{ server }}_mysql_directory
{{ server }}_init:
  cmd.run:
      {% if salt['file.file_exists']('/opt/{{ version }}/bin/mysql_install_db') %}
    - name: /opt/{{ version }}/bin/mysql_install_db --user=mysql --group=mysql --defaults-file={{ dest }}/mysql/node{{ port }}/my.node.cnf --basedir=/opt/{{ version }} --datadir={{ dest }}/mysql/node{{ port }}/data 
      {% else %}
    - name: /opt/{{ version }}/scripts/mysql_install_db --user=mysql --group=mysql --defaults-file={{ dest }}/mysql/node{{ port }}/my.node.cnf --basedir=/opt/{{ version }} --datadir={{ dest }}/mysql/node{{ port }}/data 
      {% endif %}
    - unless: ls {{ dest }}/mysql/node{{ port }}/data
    - require:
      - cmd: {{ server }}_mysql_install
  {% endfor %}
{% else %}
  {% set version = pillar['mysql']['common']['version'] %}
  {% set id = pillar['mysql']['common']['id'] %}
  {% set port = pillar['mysql']['common']['port'] %}
  {% set dest = pillar['mysql']['common']['dest'] %}
  {% set ver = version[:18] %}
{{ version }}.tar.gz:
  archive.extracted:
    - name: /opt/
    - source:
      - salt://templates/mysql/{{ version }}.tar.gz
    - archive_format: tar
    - tar_options: z
    - if_missing: /opt/{{ version }}

mysql_node_install.pl:
  file.managed:
    - name: /opt/scripts/mysql_node_install.pl
    - source: salt://templates/mysql/mysql_node_install.pl
    - mode: 755
    - makedirs: True

mysql_directory:
  file.directory:
    - name: {{ dest }}/mysql
    - makedirs: True

mysql_install:
  cmd.run:
    - name: perl /opt/scripts/mysql_node_install.pl --port={{ port }} --base=/opt/{{version }} --dest='{{ dest }}' --id={{ id }}
    - unless: ls {{ dest }}/mysql/node{{ port }}
    - require:
      - archive: {{ version }}.tar.gz
      - file: mysql_node_install.pl
      - file: mysql_directory
init:
  cmd.run:
  {% if salt['file.file_exists']('/opt/{{ version }}/bin/mysql_install_db') %}
    - name: /opt/{{ version }}/bin/mysql_install_db --user=mysql --group=mysql --defaults-file={{ dest }}/mysql/node{{ port }}/my.node.cnf --basedir=/opt/{{ version }} --datadir={{ dest }}/mysql/node{{ port }}/data 
  {% else %}
    - name: /opt/{{ version }}/scripts/mysql_install_db --user=mysql --group=mysql --defaults-file={{ dest }}/mysql/node{{ port }}/my.node.cnf --basedir=/opt/{{ version }} --datadir={{ dest }}/mysql/node{{ port }}/data 
  {% endif %}
    - unless: ls {{ dest }}/mysql/node{{ port }}/data
    - require:
      - cmd: mysql_install
{% endif %}
