FROM debian:12


RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx ssl-cert gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN make-ssl-cert generate-default-snakeoil --force-overwrite

COPY conf/default /etc/nginx/templates/default.template
COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

CMD ["/init.sh"]