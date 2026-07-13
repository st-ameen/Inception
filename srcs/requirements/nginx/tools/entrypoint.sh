#!/bin/bash
set -euo pipefail

log() {
	printf '[entrypoint] %s\n' "$1" >&2
}

require_env() {
	local var_name="$1"
	if [[ -z "${!var_name:-}" ]]; then
		log "ERROR: missing required env var: ${var_name}"
		exit 1
	fi
}

require_env DOMAIN_NAME

TEMPLATE=/etc/nginx/templates/default.template
TARGET=/etc/nginx/sites-enabled/default

if [[ ! -f "${TEMPLATE}" ]]; then
	log "ERROR: template not found at ${TEMPLATE}"
	exit 1
fi

log "Rendering nginx config for domain: ${DOMAIN_NAME}"
envsubst '${DOMAIN_NAME}' < "${TEMPLATE}" > "${TARGET}"

log "Validating nginx configuration"
nginx -t

log "Starting nginx"
exec nginx -g 'daemon off;'