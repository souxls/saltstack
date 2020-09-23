tomcat process user:
  user.present:
    - name: www
    - shell: /sbin/nologin
    - createhome: False

/etc/logrotate.d/tomcat:
  file.managed:
    - source: salt://templates/tomcat/tomcat.logrotate

{% set id = grains['id'] %}
{% for server in pillar['tomcat'][id] %}
  {% if pillar['tomcat'][id][server]['tomcat_path'] is defined %}
    {% set tomcat_path = pillar['tomcat'][id][server]['tomcat_path'] %}
  {% else %}
    {% set tomcat_path = pillar['tomcat']['common']['tomcat_path'] %}
  {% endif %}
  {% if pillar['tomcat'][id][server]['tomcat_version'] is defined %}
    {% set version = pillar['tomcat'][id][server]['tomcat_version'] %}
  {% else %}
    {% set version = pillar['tomcat']['common']['tomcat_version'] %}
  {% endif %}
  {% set ver = version[0] %}
  {% set servername = pillar['tomcat'][id][server]['servername'] %}
  {% set port = pillar['tomcat'][id][server]['port'] %}
  {% if pillar['tomcat'][id][server]['ssl'] is defined %}
    {% set ssl = pillar['tomcat'][id][server]['ssl'] %}
    {% set keystoreFile = pillar['tomcat'][id][server]['keystoreFile'] %}
    {% set keyname = keystoreFile.split('/')[-1] %}
    {% if not salt['file.directory_exists']('{{ keystoreFile }}') %}
{{ servername}}_{{ keyname }}:
  file.managed:
    - name: /etc/ssl/private/client/{{ keyname }}
    - source: salt://templates/tomcat/ssl/{{ keyname }}
    - makedirs: True
    {% endif %}
    {% if pillar['tomcat'][id][server]['clientAuth'] is defined %}
      {% set clientAuth = 'want' %}
    {% else %}
      {% set clientAuth = [] %}
      {% set keystorePass = pillar['tomcat'][id][server]['keystorePass'] %}
      {% set keystoreType = pillar['tomcat'][id][server]['keystoreType'] %}
    {% endif %}
  {% else %}
    {% set ssl = [] %}
    {% set keystoreFile = [] %}
    {% set keystorePass = [] %}
    {% set keystoreType = [] %}
    {% set clientAuth = [] %}
  {% endif %}

tomcat{{ ver }}_{{ port }}_{{ servername }}.tar.gz:
  archive.extracted:
    - name: {{ tomcat_path }}
    - source:  salt://templates/tomcat/apache-tomcat-{{ version }}.tar.gz
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}

tomcat{{ ver }}_{{ port }}_{{ servername }}:
  file.rename:
    - name: {{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}
    - source: {{ tomcat_path }}/apache-tomcat-{{ version }}
    - require:
      - archive: tomcat{{ ver }}_{{ port }}_{{ servername }}.tar.gz

{{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}:
  file.directory:
    - user: www
    - group: www
    - recurse:
      - user
      - group
    - require: 
      - file: tomcat{{ ver }}_{{ port }}_{{ servername }}

{{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}/conf/server.xml:
  file.managed:
    - source: salt://templates/tomcat/server-{{ version }}.xml
    - user: www
    - group: www
    - template: jinja
    - mode: 644
    - require:
      - file: {{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}
    - defaults:
      servername: {{ servername }}
      port: {{ port }}
      ssl: {{ ssl }} 
      keystoreFile: {{ keystoreFile }} 
      keystorePass: {{ keystorePass }}
      keystoreType: {{ keystoreType }} 
      clientAuth: {{ clientAuth }}

{% if pillar['tomcat'][id][server]['jdk_version'] is defined %}
  {% set jdk_version = pillar['tomcat'][id][server]['jdk_version'] %}
{% else %}
  {% set jdk_version = pillar['tomcat']['common']['jdk_version'] %}
{% endif %}
{% set jdk_ver = jdk_version[:3] %}
{% set jdk_ver1 = jdk_version[2] %}
{% set jdk_ver2 = jdk_version[-2::] %}
{% if pillar['tomcat'][id][server]['jdk_path'] is defined  %}
  {% set jdk_path = pillar['tomcat'][id][server]['jdk_path'] %}
{% else %}
  {% set jdk_path = pillar['tomcat']['common']['jdk_path'] %}
{% endif %}
{% set jdk = [jdk_path, ['jdk', jdk_ver]|join('')]|join('/') %}
{% if jdk_ver == '1.6' %}
  {% if not salt['file.directory_exists']('{{ jdk }}') %}
{{ servername }}_{{ jdk_path }}/jdk-{{ jdk_ver1 }}u{{ jdk_ver2 }}-linux-x64.bin:
  file.managed:
    - name: {{ jdk_path }}/jdk-{{ jdk_ver1 }}u{{ jdk_ver2 }}-linux-x64.bin 
    - source: salt://templates/tomcat/jdk-{{ jdk_ver1 }}u{{ jdk_ver2 }}-linux-x64.bin
    - replace: False
    - mode: 755
{{ servername }}_{{ jdk }}:
  cmd.run:
    - name: sh {{ jdk_path }}/jdk-{{ jdk_ver1 }}u{{ jdk_ver2 }}-linux-x64.bin
    - cwd: {{ jdk_path }}
    - unless: ls {{ jdk }}
    - require:
      - file: {{servername}}_{{ jdk_path }}/jdk-{{ jdk_ver1 }}u{{ jdk_ver2 }}-linux-x64.bin
  {% endif %}
{% else %}
{{ servername }}_{{ jdk }}:
  archive.extracted:
    - name: {{ jdk_path }}
    - source: salt://templates/tomcat/jdk-{{ jdk_ver1 }}u{{ jdk_ver2 }}-linux-x64.gz
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ jdk }}
{% endif %}

{{ servername }}_jdk{{ jdk_version }}:
  file.rename:
    - name: {{ jdk }}
    - source: {{ jdk_path }}/jdk{{ jdk_version }}
    - require:
   {% if jdk_ver == '1.6' %}
      - cmd : {{ servername }}_{{ jdk }}
   {% else %}
      - archive: {{ servername }}_{{ jdk }}
   {% endif %}

{{ servername }}_cacerts:
  file.managed:
    - name: {{ jdk }}/jre/lib/security/cacerts
    - source: salt://templates/tomcat/cacerts
    - replace: True
    - require:
   {% if jdk_ver == '1.6' %}
      - cmd : {{ servername }}_{{ jdk }}
   {% else %}
      - archive: {{ servername }}_{{ jdk }}
   {% endif %}
      
/etc/init.d/jsvc{{ port }}:
  file.managed:
    - source: salt://templates/tomcat/jsvc
    - user: root
    - group: root
    - mode: 755
    - template: jinja
    - defaults:
      servername: {{ servername }}
      port: {{ port }}
      ver: {{ ver }}
      jdk_ver: {{ jdk_ver }}

/web/www/{{ servername }}:
  file.directory:
    - user: www
    - group: www
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - recurse:
      - user
      - group
      - mode

{{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}/bin/jsvc:
  cmd.script:
    - source: salt://templates/scripts/createJsvc.sh
    - template: jinja
    - cwd: {{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}/bin/
    - unless: ls {{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}/bin/jsvc
    - require:
   {% if jdk_ver == '1.6' %}
      - cmd : {{ servername }}_{{ jdk }}
   {% else %}
      - archive: {{ servername }}_{{ jdk }}
   {% endif %}
    - statefule: True
    - defaults:
      tomcat_path: {{ tomcat_path }}
      jdk_path: {{ jdk_path }}
      ver: {{ ver }}
      port: {{ port }}
      servername: {{ servername }}
      jdk_ver: {{ jdk_ver }}

{{ servername }}_logrotate:
  cmd.run:
    - name: sed -i  "1 i {{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}/logs/catalina.out" /etc/logrotate.d/tomcat
    - unless: grep "{{ tomcat_path }}/tomcat{{ ver }}_{{ port }}_{{ servername }}/logs/catalina.out" /etc/logrotate.d/tomcat
    - require: 
      - file: /etc/logrotate.d/tomcat
{% endfor %}

