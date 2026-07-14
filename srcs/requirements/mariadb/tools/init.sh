#!/bin/bash
set -euo pipefail

MYSQL_ROOT_PASSWORD="$(< /run/secrets/mysql_root_password)"
MYSQL_PASSWORD="$(< /run/secrets/mysql_password)"

mysql_exec() {
	if [[ "${1:-}" == "--with-password" ]]; then
		shift
		mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "$@"
	else
		mysql -u root "$@"
	fi
}

if [[ -z "${MYSQL_DATABASE:-}" ]] || [[ -z "${MYSQL_USER:-}" ]]; then
	echo "Error: MYSQL_DATABASE and MYSQL_USER environment variables must be set"
	exit 1
fi

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

FIRST_INIT=false
if [[ ! -d /var/lib/mysql/mysql ]]; then
	FIRST_INIT=true
	chown -R mysql:mysql /var/lib/mysql
	mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

mysqld --user=mysql --bind-address=0.0.0.0 &
MYSQLD_PID=$!

for _ in {1..30}; do
	if mysqladmin ping --silent >/dev/null 2>&1; then
		break
	fi
	sleep 1
done

if [[ "$FIRST_INIT" == true ]]; then
	mysql_exec << SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
else
	mysql_exec --with-password << SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
fi

kill "$MYSQLD_PID"
wait "$MYSQLD_PID" 2>/dev/null || true
sleep 2

exec mysqld --user=mysql --bind-address=0.0.0.0