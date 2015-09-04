#!/bin/bash

if [ -f /.rabbitmq_password_set ]; then
	echo "RabbitMQ password already set!"
	exit 0
fi

PASS=${RABBITMQ_PASS:-$(pwgen -s 12 1)}
USER=${RABBITMQ_USER:-"admin"}
MGMTPORT=${RABBITMQ_MGMT_PORT:-15672}
_word=$( [ ${RABBITMQ_PASS} ] && echo "preset" || echo "random" )
echo "=> Securing RabbitMQ with a ${_word} password"
cat > /etc/rabbitmq/rabbitmq.config <<EOF
[
	{rabbit, [{default_user, <<"$USER">>},{default_pass, <<"$PASS">>},{tcp_listeners, [{"::", 5672}]}]}
	{rabbitmq_management, 
		[{listener, [{port,$MGMTPORT},
                 {ip, "::"}
								]}
	  ]}
].
EOF

echo "=> Done!"
touch /.rabbitmq_password_set

echo "========================================================================"
echo "You can now connect to this RabbitMQ server using, for example:"
echo ""

if [ ${_word} == "random" ]; then
    echo "    curl --user $USER:$PASS http://<host>:<port>/api/vhosts"
    echo ""
    echo "Please remember to change the above password as soon as possible!"
else
    echo "    curl --user $USER:<RABBITMQ_PASS> http://<host>:<port>/api/vhosts"
    echo ""
fi

echo "========================================================================"
