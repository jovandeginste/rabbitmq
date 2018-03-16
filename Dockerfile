FROM ubuntu:xenial
MAINTAINER Fernando Mayo <fernando@tutum.co>

# Install RabbitMQ
RUN apt-get update && \
			apt-get install -y pwgen ipset gdebi-core wget telnet curl && \
			apt-get clean && \
			(rm -rf /var/lib/apt/lists/* || true)
ENV VERSION=3.7.4
ENV RELEASE=1

# https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.4/rabbitmq-server_3.7.4-1_all.deb
RUN wget -q "https://github.com/rabbitmq/rabbitmq-server/releases/download/v${VERSION}/rabbitmq-server_${VERSION}-${RELEASE}_all.deb" -O /tmp/rabbit.deb && \
apt-get update && gdebi -n /tmp/rabbit.deb && \
apt-get clean && \
(rm -rf /var/lib/apt/lists/* || true) && \
rm -f /tmp/rabbit.deb

RUN true && rabbitmq-plugins --offline enable rabbitmq_management rabbitmq_stomp rabbitmq_shovel rabbitmq_shovel_management

RUN echo "ERLANGCOOKIE" > /var/lib/rabbitmq/.erlang.cookie
RUN chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
RUN chmod 400 /var/lib/rabbitmq/.erlang.cookie
RUN mkdir /config

# Add scripts
ADD run.sh /run.sh
ADD set_rabbitmq_password.sh /set_rabbitmq_password.sh
RUN chmod 755 ./*.sh

EXPOSE 5672 15672
CMD ["/run.sh"]
