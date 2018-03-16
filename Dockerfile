FROM ubuntu:xenial
MAINTAINER Fernando Mayo <fernando@tutum.co>

# Install RabbitMQ
RUN apt-get update && \
	apt-get install -y pwgen ipset gdebi-core wget telnet curl apt-transport-https && \
	apt-get clean && \
	(rm -rf /var/lib/apt/lists/* || true)
ENV VERSION=3.7.4
ENV RELEASE=1

# https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.4/rabbitmq-server_3.7.4-1_all.deb
RUN wget -q "http://packages.erlang-solutions.com/site/esl/esl-erlang/FLAVOUR_1_general/esl-erlang_20.2.2-1~debian~jessie_amd64.deb" -O /tmp/erlang.deb && \
	apt-get update && apt install -y /tmp/erlang.deb && \
	apt-get clean && \
	(rm -rf /var/lib/apt/lists/* || true) && \
	rm -f /tmp/erlang.deb

RUN echo "deb https://dl.bintray.com/rabbitmq/debian xenial main" > /etc/apt/sources.list.d/bintray.rabbitmq.list
RUN wget -O- https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc | apt-key add -
RUN wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add -

RUN apt-get update && apt-get install -y rabbitmq-server && \
	apt-get clean && \
	(rm -rf /var/lib/apt/lists/* || true)

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
