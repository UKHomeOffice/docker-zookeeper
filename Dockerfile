FROM quay.io/ukhomeofficedigital/centos-base:v0.2.0

RUN yum upgrade -y -q; yum clean all
RUN yum install -y -q java-headless tar wget; yum clean all

EXPOSE 2181 2888 3888

ENV ZK_VERSION 3.5.1-alpha
RUN wget -q http://mirror.ox.ac.uk/sites/rsync.apache.org/zookeeper/zookeeper-${ZK_VERSION}/zookeeper-${ZK_VERSION}.tar.gz -O - | tar -xzf -; mv zookeeper-${ZK_VERSION} /zookeeper

VOLUME /data
WORKDIR /zookeeper
COPY zoo.cfg /zookeeper/conf/zoo.cfg
COPY run.sh /run.sh

CMD /run.sh
