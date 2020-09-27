#!/bin/bash
#
#Backup rsync
#

usage() {
    echo -e "Usage: $0 -h [127.0.0.1] --password-file=[password-file] [OPTION]... [FILE|DIRECTORY]...
    --help     display this help and exit
    -h --host=name remote host for backup
    -p --password-file=file read rsync daemon-access password from FILE
    -u --user=name connect rsync daemon of user,default \"backup\"
    -m             rsync module,default \"backup\"
    --exclude=PATTERN       exclude files matching PATTERN (rsync)
    --exclude-from=FILE     read exclude patterns from FILE (rsync)
"   
   exit 1
}

##main
ARGS=$(getopt -o h:p:u::m::d:: --long help,hostname:,password-file:,user::,directory::exclude::,exclude-file:: -- "$@")
[[ $# -lt 3 ]] && usage
eval set -- "${ARGS}"

while true
do 
    case "$1" in
        --help)
            usage
            ;;
        -h|--host)
            host=$2
            shift 2
            ;;
        -p|--password-file)
            password=$2
            shift 2
            ;;
        -u|--user)
            user=$2
            shift 2
            ;;
        -m)
            module=$2
            shift 2
            ;;
        --exclude|--exclude-file)
            exclude=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "$0: $1: invalid option"
            break
            ;;
    esac
done
[[ "$user" == "" ]] && user="backup"
[[ "$module" == "" ]] && module="backup"
backup="$*"
if [[ "$exclude" != "" ]];then
    excludeList=$(echo $exclude|awk -F',' '{ORS=" "}{for(i=1;i<=NF;i++) print "--exclude=""\""$i"\""}')
    echo $excludeList
    /usr/bin/rsync -auvL  ${excludeList} --delete ${backup} ${user}@${host}::${module} --password-file=${password}
else
    /usr/bin/rsync -auqL --delete ${backup} ${user}@${host}::${module} --password-file=${password}
fi

[[ $? -eq 0 ]] && echo "backup successed "
exit $?
