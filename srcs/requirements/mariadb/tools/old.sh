#!/bin/bash
set -eu

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# 1. Check if the database has already been initialized
# We check for the 'mysql' directory inside the volume mount point.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB for the first time..."
    
    # 2. Build the basic database structure
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # 3. Start the daemon temporarily in the background
    mysqld --user=mysql --datadir=/var/lib/mysql &
    MYSQLD_PID=$!

    # 4. Wait for the temporary daemon to be fully ready to accept connections
    until mysqladmin ping --silent >/dev/null 2>&1; do
        sleep 1
    done

    # 5. Execute the SQL setup using your .env variables via a HereDoc
    echo "Configuring users and privileges..."
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # 6. Gracefully shut down the temporary background daemon
    # We must use the root password here because we just set it in the step above!
    mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
    
    # Wait for the background process to fully exit to prevent file locks
    wait "$MYSQLD_PID"
    
    echo "MariaDB initial setup complete."
else
    echo "MariaDB data directory already exists. Skipping initialization."
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql --console