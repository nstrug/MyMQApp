#!/bin/bash

set -e

log=

monitor () {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}

trap_mqm () {
    trap "echo 'Caught SIGTERM, shutting down...' ; stop_queue_managers" SIGTERM ;
    trap "echo 'Caught SIGTERM, shutting down...' ; stop_queue_managers" SIGTERM ;
}

untar () {
    chown mqm:mqm /var/mqm 
    chmod 0777 /var/mqm 
    if [ ! -f /var/mqm/mqs.ini ]; then
        echo "Uninitialised storage, unpacking /var/mqm onto persistent storage"
        pushd /
        tar xvzf /assets/var-mqm.tgz 
        popd
    fi
}

create_test_queue () {
    if [[ $(su - mqm -c dspmq | wc -l) == 0 ]]; then
        echo "No queues defined, creating a test queue"
        su - mqm -c "crtmqm MYAPPQ1"
        su - mqm -c "crtmqm MYAPPQ2"
        su - mqm -c "crtmqm MYAPPQ3"
        su - mqm -c "crtmqm MYAPPQ4"
        su - mqm -c "crtmqm MYAPPQ5"
        su - mqm -c "crtmqm MYAPPQ6"
    fi
}

start_queue_managers () {
    trap_mqm
    PORT=1414
    for I in $(su - mqm -c dspmq | sed 's/^QMNAME(\(.*\)) .*/\1/')
    do
        su - mqm -c "strmqm $I" &
        su - mqm -c "runmqlsr -m $I -p $PORT" &
        monitor /var/mqm/qmgrs/$I/errors/AMQERR01.LOG $I &
        (( PORT++ ))
    done
}

stop_queue_managers () {
    trap '' SIGINT SIGTERM
        for I in $(su - mqm -c dspmq | sed 's/^QMNAME(\(.*\)) .*/\1/')
        do
            echo "Shutting down queue $I"
            su - mqm -c "endmqlsr -m $I"
            su - mqm -c "endmqm -i $I" 
        done
        exit 0
}

untar var_mqm
create_test_queue
start_queue_managers
wait


