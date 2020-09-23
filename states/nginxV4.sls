nginx:
  pkg.installed:
    - fromrepo: nginx
    - skip_verify: True
    - allow_updates: False
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nginx/vhosts/*.conf


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
    - source: salt://templates/nginx/nginxV4.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - backup: minion
    - requre:
      - pkg: nginx

{% set id = grains['id'] %}
{% for server in pillar['nginx'][id] %}
  {% if pillar['nginx'][id][server]['upstream'] is defined %}
    {% set upstream = pillar['nginx'][id][server]['upstream'].split(',') %}
  {% else %}
    {% set upstream = [] %}
  {% endif %}
  {% set upstreamname = server.replace('.','_') %}
  {% set port = pillar['nginx'][id][server]['port'] %}
  {% if pillar['nginx'][id][server]['ext'] is defined %}
    {% set ext = pillar['nginx'][id][server]['ext'].split(',') %}
  {% else %}
    {% set ext = [] %}
  {% endif %}

/etc/nginx/vhosts/{{ server }}.conf:
  file.managed:
    - source: salt://templates/nginx/vhostsV4.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: nginx
      - file: /etc/nginx/vhosts
    - backup: minion
    - defaults:
      port: {{ port }}
      upstreamname: {{ upstreamname }}
      upstream: {{ upstream }}
      ext: {{ ext }}
{% endfor %}

