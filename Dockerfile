FROM ubuntu:18.04

RUN apt update
RUN apt install -y openjdk-8-jre python less curl openssh-server openssh-client
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Setup Hadoop
RUN curl -s http://apache.mirrors.ionfish.org/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz | tar -xzf -C /root
RUN mkdir /root/hadoop-2.9.2/dfs
COPY hadoop/hadoop-env.sh /root/hadoop-2.9.2/etc/hadoop/hadoop-env.sh
COPY hadoop/core-site.xml /root/hadoop-2.9.2/etc/hadoop/core-site.xml
COPY hadoop/hdfs-site.xml /root/hadoop-2.9.2/etc/hadoop/hdfs-site.xml

## ssh without password
RUN ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN chmod 0600 /root/.ssh/authorized_keys
COPY ssh_config /root/.ssh/config
RUN chmod 400 /root/.ssh/config

ENV HADOOP_HOME /root/hadoop-2.9.2

## Format namenode
RUN /root/hadoop-2.9.2/bin/hdfs namenode -format


# Setup Hive
RUN curl -s http://apache.mirrors.ionfish.org/hive/hive-2.3.6/apache-hive-2.3.6-bin.tar.gz | tar -xzf -C /root
COPY hive/hive-site.xml /root/apache-hive-2.3.6-bin/conf/hive-site.xml
COPY hive/postgresql-42.2.6.jar /root/apache-hive-2.3.6-bin/lib/postgresql-42.2.6.jar

## Setup Postgres
RUN DEBIAN_FRONTEND=noninteractive apt install -y postgresql postgresql-contrib
RUN su postgres -c '/usr/lib/postgresql/10/bin/initdb -D /var/lib/postgresql/10/main2 --auth-local trust --auth-host md5'


# Setup Presto
RUN curl -s https://repo1.maven.org/maven2/io/prestosql/presto-server/318/presto-server-318.tar.gz | tar -xzf -C /root
RUN curl -o /root/prseto-server-317/bin/presto-cli https://repo1.maven.org/maven2/io/prestosql/presto-cli/318/presto-cli-318-executable.jar
RUN chmod +x /root/prseto-server-317/bin/presto-cli
COPY presto/catalog /root/presto-server-317/etc/catalog
COPY presto/jvm.config /root/presto-server-317/etc/jvm.config
COPY presto/config.properties /root/presto-server-317/etc/config.properties
COPY presto/log.properties /root/presto-server-317/etc/log.properties
COPY presto/node.properties /root/presto-server-317/etc/node.properties


# Copy setup script
COPY start_services.sh /root/start_services.sh
RUN chown root:root /root/start_services.sh
RUN chmod 700 /root/start_services.sh

# Start services
CMD ["/root/start_services.sh"]

EXPOSE 8080