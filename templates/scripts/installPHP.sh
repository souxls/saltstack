#!/bin/bash
#
#
#

php_path = {{ php_path }}
php_source = {{ php_path}}/php-{{ php_version }}
php_opts = "{{ ext }}"

cd ${php_path}
tar xf ${php_source}.tar.gz
cd ${php_source}
./configure --prefix=${php_path} ${ext} && make && make install
