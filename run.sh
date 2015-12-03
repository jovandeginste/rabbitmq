#!/bin/bash

set -m
: ${RABBITMQ_CHAIN:=rabbitmq-local}

if [ ! -f /config/.rabbitmq_password_set ]; then
	/set_rabbitmq_password.sh
fi

IPV6=`ip -6 addr list dev eth0 | grep global | sed "s/.*inet6 //;s+/80.*++"`

# make rabbit own its own files
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

if [ -z "$CLUSTER_WITH" ] ; then
    /usr/sbin/rabbitmq-server &
    sleep 5
    PORT=`epmd -names | sed '/rabbit/!d;s/.*port //'`
    ipset -! add ${RABBITMQ_CHAIN} ${IPV6}
    fg
else
    if [ -f /config/.CLUSTERED ] ; then
    /usr/sbin/rabbitmq-server
    else
        touch /config/.CLUSTERED
        /usr/sbin/rabbitmq-server &
        sleep 10
        PORT=`epmd -names | sed '/rabbit/!d;s/.*port //'`
        ipset -! add ${RABBITMQ_CHAIN} ${IPV6}
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@$CLUSTER_WITH
        rabbitmqctl start_app
        fg
    fi
fi

