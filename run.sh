#!/bin/bash

set -m

: ${DNS_DELAY:=60}
: ${CLUSTER_WITH:=}

if [[ ! -f /config/.rabbitmq_password_set ]]; then
	/set_rabbitmq_password.sh
fi

if [[ ! -f /var/lib/rabbitmq/.erlang.cookie ]]; then
	echo "ERLANGCOOKIE" >/var/lib/rabbitmq/.erlang.cookie
	chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
	chmod 400 /var/lib/rabbitmq/.erlang.cookie
fi

# make rabbit own its own files
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

SELF=$(hostname -f)

if [[ -z ${CLUSTER_WITH} ]] || [[ ${CLUSTER_WITH} == "${SELF}" ]]; then
	/opt/rabbitmq/sbin/rabbitmq-server
else
	if [ -f /config/.CLUSTERED ]; then
		# Node is clustered, just start the cluster
		/opt/rabbitmq/sbin/rabbitmq-server
	else
		/opt/rabbitmq/sbin/rabbitmq-server &

		echo "Wait for the (local) server to start."
		sleep 10

		echo -n "Trying to resolve '${CLUSTER_WITH}' (max. ${DNS_DELAY} seconds.) "
		for i in {1..${DNS_DELAY}}; do
			echo -n "."
			getent hosts "${CLUSTER_WITH}" && break
		done

		echo

		if getent hosts "${CLUSTER_WITH}"; then
			echo "DNS resolution of '${CLUSTER_WITH}' successful."
		else
			echo "Failed to resolve DNS for '${CLUSTER_WITH}' within ${DNS_DELAY} seconds. Bailing out."
			exit 1
		fi

		/opt/rabbitmq/sbin/rabbitmqctl stop_app
		if /opt/rabbitmq/sbin/rabbitmqctl join_cluster rabbit@${CLUSTER_WITH}; then
			echo "Clustering with 'rabbit@${CLUSTER_WITH}' was successful."
			touch /config/.CLUSTERED
		else
			echo "Failed to cluster with 'rabbit@${CLUSTER_WITH}'. Bailing out."
			exit 1
		fi
		/opt/rabbitmq/sbin/rabbitmqctl start_app
		fg
	fi
fi
