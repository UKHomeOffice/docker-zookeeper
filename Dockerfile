FROM alpine:3.3

RUN apk upgrade

RUN apk add --update --no-cache openjdk8-jre bash

EXPOSE 2181 2888 3888

ENV ZK_VERSION 3.5.1-alpha
RUN wget -q http://mirror.ox.ac.uk/sites/rsync.apache.org/zookeeper/zookeeper-${ZK_VERSION}/zookeeper-${ZK_VERSION}.tar.gz -O - | tar -xzf -; mv zookeeper-${ZK_VERSION} /zookeeper

VOLUME /data
WORKDIR /zookeeper
COPY zoo.cfg /zookeeper/conf/zoo.cfg
COPY run.sh /run.sh

CMD /run.sh
