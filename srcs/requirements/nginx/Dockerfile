FROM debian:12

# Install nginx, the ssl-cert package (self-signed cert tooling), gettext-base
# (provides envsubst — needed by entrypoint.sh to render the vhost template),
# and curl (used by the HEALTHCHECK below).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       nginx \
       ssl-cert \
       gettext-base \
       curl \
    && rm -rf /var/lib/apt/lists/*

# Generate a self-signed ("snakeoil") certificate/key pair for TLS.
RUN make-ssl-cert generate-default-snakeoil --force-overwrite

# Remove Debian's stock default vhost (both the sites-enabled symlink and its
# sites-available target) so nothing conflicts with our own rendered config.
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

# nginx vhost template — rendered into sites-enabled/default by entrypoint.sh
# at container start (envsubst substitutes ${DOMAIN_NAME}).
COPY conf/default /etc/nginx/templates/default.template

# Entrypoint script: validates env vars, renders the template, execs nginx.
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Static site content, copied last: it changes most often during development,
# so keeping it as the final layer means editing index.html doesn't invalidate
# the more expensive apt-get/cert layers above on rebuild.
COPY html/ /var/www/html/

EXPOSE 443

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
	CMD curl -k -f https://localhost/ || exit 1

CMD ["/entrypoint.sh"]