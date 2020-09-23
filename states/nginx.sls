nginx:
  pkg.installed:
    - fromrepo: nginx
    - skid_verify: True
    - allow_updates: False
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nginx/vhosts/*.conf

{{ pillar['nginx']['common']['log'] }}:
  file.directory:
    - user: nginx
    - group: nginx
    - mode: 755
    - makedirs: True
    - recurse:
      - user
      - group
      - mode

sed -i "s#/var/log/nginx#{{ pillar['nginx']['common']['log'] }}#" /etc/logrotate.d/nginx:
  cmd.run:
    - onlyif: grep "/var/log/nginx" /etc/logrotate.d/nginx
    - require: 
      - pkg: nginx


/etc/nginx/vhosts:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - requre:
      - pkg: nginx

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://templates/nginx/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - backup: minion
    - requre:
      - pkg: nginx

{% set id = grains['id'] %}
{% for server in pillar['nginx'][id] %}
  {% set servernamelist = pillar['nginx'][id][server]['servername'].replace(',',' ') %}
  {% set servername = pillar['nginx'][id][server]['servername'].split(',')[0] %}
  {% if pillar['nginx'][id][server]['upstream'] is defined %}
    {% set upstream = pillar['nginx'][id][server]['upstream'].split(',') %}
  {% else %}
    {% set upstream = [] %}
  {% endif %}
  {% set upstreamname = servername.replace('.','_') %}
  {% if pillar['nginx'][id][server]['location'] is defined %}
    {% set location = pillar['nginx'][id][server]['location'].split(',') %}
  {% else %}
    {% set location = [] %}
  {% endif %}
  {% if pillar['nginx'][id][server]['ext'] is defined %}
    {% set ext = pillar['nginx'][id][server]['ext'].split(',') %}
  {% else %}
    {% set ext = [] %}
  {% endif %}


/etc/nginx/vhosts/{{ server }}.conf:
  file.managed:
    - source: salt://templates/nginx/vhosts.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: nginx
      - file: /etc/nginx/vhosts
    - backup: minion
    - defaults:
      servername: {{ servername }}
      upstreamname: {{ upstreamname }}
      upstream: {{ upstream }}
      servernamelist: {{ servernamelist }}
      location: {{ location }}
      ext: {{ ext }}
{% endfor %}
