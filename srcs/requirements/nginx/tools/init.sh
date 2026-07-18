#!/bin/bash
set -euo pipefail

: "${DOMAIN_NAME:?Missing DOMAIN_NAME env var}"

# Render nginx vhost from template using DOMAIN_NAME
if [[ -f /etc/nginx/templates/default.template ]]; then
	envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/default.template > /etc/nginx/sites-enabled/default
fi

exec nginx -g 'daemon off;'
