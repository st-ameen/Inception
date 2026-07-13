FROM debian:12

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    mkdir -p /var/run/mysqld && \
    chown -101:101 /var/run/mysqld && \
    chmod 777 /var/run/mysqld

COPY tools/init.sh ./init.sh

RUN chmod +x init.sh

CMD ["./init.sh"]