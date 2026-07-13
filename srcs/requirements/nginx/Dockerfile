FROM debian:12

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       nginx \
       ssl-cert \
       gettext-base \
       curl \
    && rm -rf /var/lib/apt/lists/*

RUN make-ssl-cert generate-default-snakeoil --force-overwrite

RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

COPY conf/default /etc/nginx/templates/default.template

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY html/ /var/www/html/

EXPOSE 443

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
	CMD curl -k -f https://localhost/ || exit 1

CMD ["/entrypoint.sh"]