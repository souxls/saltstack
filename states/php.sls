php process user:
  user.present:
    - name: www
    - shell: /sbin/nologin
    - createhome: False

libxml2-devel:
  pkg.installed
bzip2-devel:
  pkg.installed
libcurl-devel:
  pkg.installed
libjpeg-turbo-devel:
  pkg.installed
libvpx-devel:
  pkg.installed
libpng-devel:
  pkg.installed
libXpm-devel:
  pkg.installed
gmp-devel:
  pkg.installed
libmcrypt-devel:
  pkg.installed
libxslt-devel:
  pkg.installed
openssl-devel:
  pkg.installed

{% set lan = pillar['lan'] %}
{% set ip = ''.join(grains['ip4_interfaces'][lan][0]) %}
{% if pillar['php'][ip] is defined %}
  {% if pillar['php'][ip]['version'] is defined %}
    {% set version = pillar['php'][ip]['version'] %}
  {% else %}
    {% set version = pillar['php']['common']['version'] %}
  {% endif %}
  {% if pillar['php'][ip]['path'] is defined %}
    {% set path = pillar['php'][ip]['path'] %}
  {% else %}
    {% set path = pillar['php']['common']['path'] %}
  {% endif %}
  {% if pillar['php'][ip]['ext'] is defined %}
    {% set ext = pillar['php'][ip]['ext'] %}
  {% else %}
    {% set ext = pillar['php']['common']['ext'] %}
  {% endif %}
  {% if pillar['php'][ip]['log'] is defined %}
    {% set log = pillar['php'][ip]['log'] %}
  {% else %}
    {% set log = pillar['php']['common']['log'] %}
  {% endif %}
  {% if pillar['php'][ip]['port'] is defined %}
    {% set port = pillar['php'][ip]['port'] %}
  {% else %}
    {% set port = pillar['php']['common']['port'] %}
  {% endif %}
{% else %}
    {% set version = pillar['php']['common']['version'] %}
    {% set path = pillar['php']['common']['path'] %}
    {% set ext = pillar['php']['common']['ext'] %}
    {% set log = pillar['php']['common']['log'] %}
    {% set ext = pillar['php']['common']['ext'] %}
    {% set port = pillar['php']['common']['port'] %}
{% endif %}
{% if not salt['file.path_exists_glob']('{{ path }}/php-{{ version }}') %}
php-{{ version }}.tar.gz:
  file.managed:
    - name: /usr/src/php-{{ version }}.tar.gz
    - source: salt://templates/php/php-{{ version }}.tar.gz
#    - source: http://cn2.php.net/distributions/php-{{ version }}.tar.gz
{{ path }}/php-{{ version }}:
  cmd.run:
    - name: cd /usr/src;tar xf php-{{ version }}.tar.gz ;cd /usr/src/php-{{ version }};./configure --prefix={{ path }}/php-{{ version }} --with-config-file-path={{ path }}/php-{{ version }}/etc/ {{ ext }} && make && make install
    - unless: ls {{ path }}/php-{{ version }}
    - require:
      - file: php-{{ version }}.tar.gz
{% endif %}

{{ path }}/php-{{ version }}/etc/php-fpm.conf:
  file.managed:
    - source: salt://templates/php/php-fpm.conf
    - template: jinja
    - require:
      - cmd: {{ path }}/php-{{ version }}
    - defaults:
      path: {{ path }}
      version: {{ version }}
      port: {{ port }}
      log: {{ log }}

{{ path }}/php-{{ version }}/etc/php.ini:
  file.managed:
    - source: salt://templates/php/php.ini
    - template: jinja
    - require:
      - cmd: {{ path }}/php-{{ version }}
    - defaults:
      path: {{ path }}
      version: {{ version }}
      port: {{ port }}
      log: {{ log }}

/etc/logrotate.d/php-fpm:
  file.managed:
    - source: salt://templates/php/php-fpm-logrotate
    - templates: jinja
      log: {{ log }}

{{ log }}:
  file.directory:
    - user: www
    - makedirs: True
    - recurse:
      - user

/etc/init.d/php-fpm-{{ version }}:
  file.managed:
    - source: salt://templates/php/php-fpm-init
    - template: jinja
    - mode: 755
    - defaults:
      version: {{ version }}
      path: {{ path }}
