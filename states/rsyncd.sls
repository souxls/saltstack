{% set id = grains['id'] %}
{{ id }} rsync config file:
  file.managed:
    - name: /etc/rsyncd/rsyncd.conf
    - source: salt://templates/rsyncd/rsyncd.conf
    - makedirs: True
{% if pillar['rsyncd'][id] is defined %}
  {% for module in pillar['rsyncd'][id] %}
     {% set path = pillar['rsyncd'][id][module]['path'] %}
     {% set password = pillar['rsyncd'][id][module]['password'] %}
     {% set user = pillar['rsyncd'][id][module]['user'] %}
     {% set host = pillar['rsyncd'][id][module]['host_allow'] %}

{{ module }} {{ user }} password file:
  file.managed:
    - name: /etc/rsyncd/rsyncd.pass
    - mode: 600
    - makedirs: True

{{ module }} {{ user }} password:
  file.append:
    - name: /etc/rsyncd/rsyncd.pass
    - template: jinja
    - text:  
      - {{ user }}:{{ password }}
    - require:
      - file: {{ module }} {{ user }} password file

{{ module }} rsyncd config file:
  file.blockreplace:
    - name: /etc/rsyncd/rsyncd.conf
    - marker_start: "# {{ module }}: START managed by salt  -DO-NOT-EDIT-"
    - marker_end: "# {{ module }}: END managed by salt \n"
    - content: '[{{ module }}]'
    - append_if_not_found: True
    - show_changes: True

rsyncd-{{ module }}-append:
  file.accumulated:
    - filename: /etc/rsyncd/rsyncd.conf
    - name: rsyncd-{{ module }}-append
    - text: |
         path = {{ path }}
         auth users = {{ user }}
         host allow = {{ host }}
    - require_in:
      - file: {{ module }} rsyncd config file
  {% endfor %}
{% endif %}

