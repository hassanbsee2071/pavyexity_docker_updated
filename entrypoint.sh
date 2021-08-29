#!/bin/bash
service nginx start
php-fpm
chown -R www-data:www-data /var/www/
