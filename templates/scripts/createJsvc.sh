#!/bin/bash
#
#
#

tomcat=/web/tomcat{{ ver }}_{{ port }}_{{ servername }}
jdk=/usr/local/jdk{{ jdk_ver }}
ret=''

cd $tomcat/bin
[[ ! -f ./commons-daemon-1.0.15-native-src ]] && tar xf commons-daemon-native.tar.gz
cd ./commons-daemon-1.0.15-native-src/unix
./configure --with-java=$jdk >/dev/null 2>&1 && make >/dev/null 2>&1  && make install >/dev/null 2>&1
[[ -f ./jsvc ]] &&cp ./jsvc ../../ && chmod +x ../../jsvc
