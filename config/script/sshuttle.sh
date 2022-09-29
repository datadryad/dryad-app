#!/usr/bin/env bash
FILE=~/sshuttle.pid

# these are the servers we want to tunnel through the server that has access
domain_arr="uc3-dryadsolrx2-dev.cdlib.org uc3-dryadsolrx2-stg.cdlib.org \
rds-uc3-dryad-prd.cmcguhglinoa.us-west-2.rds.amazonaws.com \
uc3db-dash2-dev.cdlib.org \
uc3db-dash2-stg.cdlib.org \
uc3-dryadsolrx2-prd.cdlib.org \
merritt-stage.cdlib.org mrtsword-stg.cdlib.org mrtoai-stg.cdlib.org \
ias-puppet2-ops.cdlib.org puppet.cdlib.org \
search-os-uc3-logging-stg-suwz42vownvyte6ivqazeifz44.us-west-2.es.amazonaws.com"

# make an array of all the IP addresses for the hosts in the domains in the array above
declare -a out_array
for i in "${domain_arr[@]}"
do
    my_output="$(dig +short $i | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')"
    while read -r line; do
        out_array+=("$line")
    done <<< "$my_output"
done
# echo ${out_array[@]}

case "$1" in
    start)
        if [ -f $FILE ]; then
            echo "sshuttle is already started"
        else
            echo "Starting sshuttle and tunneling these IPs: ${out_array[*]}"
            sshuttle -r "$DRYAD_FTP_CONNECT" ${out_array[@]} -D --pidfile $FILE
        fi
        ;;
    stop)
        if [ -f $FILE ]; then
            kill `cat $FILE`
        else
            echo "sshuttle doesn't seem to be running"
        fi
        ;;
    status)
        if [ -f $FILE ]; then
            echo "sshuttle is started with pid `cat $FILE` or at least the PID file says so"
        else
            echo "sshuttle is stopped, or at least can't find the PID file"
        fi
        ;;
    *)
        echo $"Usage: $PROG {start|stop|status}"
        error=2
        ;;
esac
