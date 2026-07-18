#!/bin/bash
set -eu

MYSQL_PASSWORD="$(< /run/secrets/mysql_password)"
WP_ADMIN_PASSWORD="$(< /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(< /run/secrets/wp_user_password)"

mkdir -p /run/php

# 1. Navigate to the website root directory
cd /var/www/html

# 2. Wait for MariaDB to be fully ready
echo "Waiting for MariaDB..."
until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    sleep 2
done
echo "MariaDB is ready!"

# 3. Download WordPress if not already present
if [ ! -f "wp-settings.php" ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
fi

# 4. Generate the wp-config.php file
if [ ! -f "wp-config.php" ]; then
    echo "Creating WordPress configuration..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root
fi

# 5. Perform the installation and create users
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
    echo "Installing WordPress core..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "Creating second WordPress user..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
else
    echo "WordPress is already installed."
fi

# 6. Apply optimal permissions for the webserver (www-data)
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# 7. Start PHP-FPM in the foreground (PID 1)
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F