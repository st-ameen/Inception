FROM debian:12

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
    php-fpm php-mysql curl ca-certificates mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init.sh ./init.sh

RUN chmod +x init.sh

CMD ["./init.sh"]