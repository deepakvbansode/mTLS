#!/bin/bash

# Install Apache if not already installed
apt-get update && apt-get install -y apache2

# Enable required modules
apachectl -v
a2enmod proxy
a2enmod proxy_http
a2enmod ssl
a2enmod headers

cp 000-default.conf /etc/apache2/sites-enabled/000-default.conf
cp ports.conf /etc/apache2/ports.conf

# Enable site
a2ensite 000-default.conf

# Restart Apache
#service apache2 restart
apachectl -D FOREGROUND
 

