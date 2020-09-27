#!/bin/bash
#
#

usage() {
    echo -e  "Usage: $0 -P [port]
or: $0 -p [pid]

Get informatoin for java program

    -h  --help     display this help and exit
    -P  --port=PORT tomcat port
    -p  --pid      java program pid
    "
    exit 1
}

dellog() {
    days=$1
    find /tmp/ -maxdepth 1 -name "tomcat*core*.log" -mtime +${days} -exec rm -f {} \;
}
#main
ARGS=$(getopt -o hp:j:P: --long help,port:,jdk:,pid: -- "$@")
[ $# -lt 1 -o $# -gt 2 ] && usage
eval set -- "${ARGS}"

while true
do
    case $1 in
        -h|--help)
            usage
            ;;
        -P|--port)
            PORT=$2
            shift 2
            ;;
        -p|--pid)
            PID=$2
            shift 2
            ;;
        --)
           shift
           break
           ;;
       *)
           echo "$0: $1: invalid option"
           usage
           break
           ;;
    esac
done
#delete old logs
dellog 1
if [[ $PORT == "" ]];then
    for i in $(netstat -ptln|awk -F':' '/'$PID'/{print $4}')
    do
        ls /etc/init.d/jsvc*|grep $i >/dev/null&&PORT=$i
    done
    [[ $PORT == "" ]] && echo "program pid is not pid of java program"
fi
[[ $PID == "" ]] && PID=$(ps aux|awk -v port=$PORT '/'$PORT'/&&/Sl/&& ! /awk/{print $2}')
JDK_PATH=$(awk -F'=' '/^JAVA_HOME/{print $2}' /etc/init.d/jsvc${PORT})
NAME=$(ps aux|awk -v port=$PORT '/'$PORT'/&&/Sl/&& ! /awk/{print "tomcat"port}')
DATE=$(date +'%Y%m%d%H%M')
LOG=/tmp/$NAME-core-$DATE.log
echo "====MEMORY:free -m==============" | tee -a $LOG
free -m |tee -a $LOG
echo "====Thread:top -H -p $PID -n1 -b ====" |tee -a /tmp/$NAME-core-thread-$DATE.log
for((i=0;i<10;i++))
do
    echo "===$(date +'%c')=========" |tee -a /tmp/$NAME-core-thread-$DATE.log
    top -H -p $PID -n1 -b |tee -a /tmp/$NAME-core-thread-$DATE.log
    sleep 3
done
echo "====jstat:${JDK_PATH}/bin/jstat -gcutil  $PID 1000 100============" |tee -a $LOG
sudo -u www -s ${JDK_PATH}/bin/jstat -gcutil  $PID 1000 100 |tee -a $LOG
echo "====jstack:${JDK_PATH}/bin/jstack -l $PID============" 
for((i=0;i<10;i++))
do
    echo "===$(date +'%c')=========" |tee -a /tmp/$NAME-core-jstack-$DATE.log
    sudo -u www -s ${JDK_PATH}/bin/jstack -l $PID |tee -a /tmp/$NAME-core-jstack-$DATE.log
    sleep 3
done
echo "====${JDK_PATH}/bin/jmap -heap $PID ==========" |tee -a $LOG
${JDK_PATH}/bin/jmap -heap $PID |tee -a $LOG
echo "====${JDK_PATH}/bin/jmap -dump:format=b,file=/tmp/$NAME-core-jmap-$DATE.log $PID ===="
sudo -u www ${JDK_PATH}/bin/jmap -dump:format=b,file=/tmp/$NAME-core-jmap-$DATE.log $PID 
echo "finished."
