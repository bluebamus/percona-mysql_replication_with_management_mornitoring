FROM centos:8

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="Percona Server for MySQL"
LABEL org.label-schema.vendor="Percona"
LABEL org.label-schema.description="Percona Server for MySQL® is a free, fully compatible, \
enhanced and open source drop-in replacement for any MySQL database. \
It provides superior performance, scalability and instrumentation."
LABEL org.label-schema.license="GPLv2"

LABEL org.opencontainers.image.title="Percona Server for MySQL"
LABEL org.opencontainers.image.vendor="Percona"
LABEL org.opencontainers.image.description="Percona Server for MySQL® is a free, fully compatible, \
enhanced and open source drop-in replacement for any MySQL database. \
It provides superior performance, scalability and instrumentation."
LABEL org.opencontainers.image.license="GPLv2"
LABEL org.opencontainers.image.authors="info@percona.com"

ENV PS_VERSION 8.0.21-12.2
ENV OS_VER el8
ENV FULL_PERCONA_VERSION "$PS_VERSION.$OS_VER"
LABEL org.label-schema.schema-version=${PS_VERSION}
LABEL org.opencontainers.image.version=${PS_VERSION}

RUN groupadd -g 1001 mysql; \
    useradd -u 1001 -r -g 1001 -s /sbin/nologin \
		-c "Default Application User" mysql

# check repository package signature in secure way
RUN set -ex; 
RUN     export GNUPGHOME="$(mktemp -d)"; 
#RUN     gpg --batch --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A 99DB70FAE1D7CE227FB6488205B555B38483C65D; 
RUN     gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A 99DB70FAE1D7CE227FB6488205B555B38483C65D; 

RUN     gpg --batch --export --armor 430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A > ${GNUPGHOME}/RPM-GPG-KEY-Percona; 
RUN     gpg --batch --export --armor 99DB70FAE1D7CE227FB6488205B555B38483C65D > ${GNUPGHOME}/RPM-GPG-KEY-centosofficial; 
RUN     rpmkeys --import ${GNUPGHOME}/RPM-GPG-KEY-Percona ${GNUPGHOME}/RPM-GPG-KEY-centosofficial; 
RUN     curl -Lf -o /tmp/percona-release.rpm https://repo.percona.com/yum/percona-release-latest.noarch.rpm; 
RUN     rpmkeys --checksig /tmp/percona-release.rpm; 
RUN     dnf install -y /tmp/percona-release.rpm; 
RUN     rm -rf "$GNUPGHOME" /tmp/percona-release.rpm; 
RUN     rpm --import /etc/pki/rpm-gpg/PERCONA-PACKAGING-KEY; 
RUN     percona-release disable all; 
RUN     percona-release setup -y ps80

RUN set -ex; \
    dnf install -y \
        percona-server-server-${FULL_PERCONA_VERSION} \
        percona-server-tokudb-${FULL_PERCONA_VERSION} \
        percona-server-devel-${FULL_PERCONA_VERSION} \
        percona-server-rocksdb-${FULL_PERCONA_VERSION} \
        jemalloc \
        which \
        cracklib-dicts \
        policycoreutils; \
    \
    dnf clean all; \
    rm -rf /var/cache/dnf /var/lib/mysql

# purge and re-create /var/lib/mysql with appropriate ownership
RUN /usr/bin/install -m 0775 -o mysql -g root -d /var/lib/mysql /var/run/mysqld /docker-entrypoint-initdb.d; \
# comment out a few problematic configuration values
	find /etc/my.cnf /etc/my.cnf.d -name '*.cnf' -print0 \
		| xargs -0 grep -lZE '^(bind-address|log|user)' \
		| xargs -rt -0 sed -Ei 's/^(bind-address|log|user)/#&/'; \
# don't reverse lookup hostnames, they are usually another container
	echo '!includedir /etc/my.cnf.d' >> /etc/my.cnf; \
	printf '[mysqld]\nskip-host-cache\nskip-name-resolve\n' > /etc/my.cnf.d/docker.cnf; \
# TokuDB modifications
	/usr/bin/install -m 0664 -o mysql -g root /dev/null /etc/sysconfig/mysql; \
	echo "LD_PRELOAD=/usr/lib64/libjemalloc.so.1" >> /etc/sysconfig/mysql; \
	echo "THP_SETTING=never" >> /etc/sysconfig/mysql; \
# allow to change config files
	chown -R mysql:root /etc/my.cnf /etc/my.cnf.d; \
	chmod -R ug+rwX /etc/my.cnf /etc/my.cnf.d

# install node_exporter, mysqld_exporter
USER root

COPY ["start_node_exporter.sh", \
      "start_mysqld_exporter.sh", \
      ".my.cnf","/tmp/"]

RUN chmod 777 /tmp/*

RUN yum install -y perl.x86_64 \
    libaio.x86_64 \
    numactl-libs.x86_64 \
    net-tools.x86_64 \
    sudo.x86_64 \
    openssl.x86_64 \
    wget 

WORKDIR /tmp/

RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz 

RUN wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.13.0/mysqld_exporter-0.13.0.linux-amd64.tar.gz

RUN mkdir -p /opt/exporters/ && \
    tar -xzvf ./node_exporter-1.3.1.linux-amd64.tar.gz -C /opt/exporters && \
    tar -xzvf ./mysqld_exporter-0.13.0.linux-amd64.tar.gz -C /opt/exporters

WORKDIR /opt/exporters/

RUN mv node_exporter-1.3.1.linux-amd64 node_exporter && \
    mv mysqld_exporter-0.13.0.linux-amd64 mysqld_exporter && \
    mv /tmp/start_node_exporter.sh /opt/exporters/node_exporter/ && \
    mv /tmp/start_mysqld_exporter.sh /opt/exporters/mysqld_exporter/ && \
    mv /tmp/.my.cnf /opt/exporters/mysqld_exporter/ && \
    chmod o+x /opt/exporters/node_exporter/start_node_exporter.sh && \
    chmod o+x /opt/exporters/mysqld_exporter/start_mysqld_exporter.sh && \
    rm -rf /tmp/*.rpm && \
    /usr/bin/install -m 0775 -o mysql -g mysql -d /var/lib/mysql \
    /var/run/mysqld /docker-entrypoint-initdb.d

VOLUME ["/var/lib/mysql", "/var/log/mysql","/etc/percona-server.conf.d"]

COPY ps-entry.sh /tmp/docker-entrypoint.sh
RUN chmod +x /tmp/docker-entrypoint.sh
ENTRYPOINT ["/tmp/docker-entrypoint.sh"]

USER mysql
EXPOSE 3306 33060
CMD ["mysqld"]