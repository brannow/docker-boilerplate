#!/bin/bash
#
# This script fix docker/host user access problems
# and changed the apache user to the current (prevents access problems)
#
# !!!! WARNING !!!! this is not for Production usage
# on Production installation let the user to the specified Web user!
#

PROBEDDIR="/app"
# use these names if no user with matching ids where found
ANONUSER="docker-user"
ANONGRP="docker-group"

# collect current system user information from the PROBEDDIR
echo "allocate current system information"
USERID=$(stat -c '%u' $PROBEDDIR)
GRPID=$(stat -c '%u' $PROBEDDIR)
USERNAME=$(awk -v val=$USERID -F ":" '$3==val{print $1}' /etc/passwd)
USERGRP=$(awk -v val=$GRPID -F ":" '$3==val{print $1}' /etc/group)

#create group of not exist
if [ -z "$USERGRP" ]; then
    addgroup --gid $GRPID $ANONGRP
    USERGRP=$ANONGRP
    echo "create new group ($GRPID:$ANONGRP)"
fi

# create user if uid not exist
if [ -z "$USERNAME" ]; then
    mkdir -p /home/$ANONUSER
    useradd --uid $USERID --gid $GRPID -d /home/$ANONUSER $ANONUSER
    USERNAME=$ANONUSER
    echo "create new user ($USERID:$USERNAME) with group ($GRPID:$USERGRP)"
fi

echo "set working user to $USERNAME:$USERGRP"

######
# change user permissions
######

chown -R $USERNAME /usr/local/bin

#npm
if [ -f "/usr/bin/nodejs" ] && [ ! -f "/usr/bin/node" ]
then
    ln -s /usr/bin/nodejs /usr/bin/node
fi

mkdir -p /usr/local/lib/node_modules
mkdir -p /usr/lib/node_modules

if [ -f "/usr/bin/node" ]
then
    echo "update npm and node to the newest version"
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - && apt-get install -y nodejs
    node -v
    npm -v
fi

hash grunt 2>/dev/null || { echo "install grunt"; npm install -g grunt; }
hash bower 2>/dev/null || { echo "install bower";npm install -g bower; }

if [ -d "/usr/local/lib/node_modules" ]; then
    echo "fix npm permissions"
    chown -R $USERNAME:$USERGRP /usr/local/lib/node_modules
fi

if [ -d "/usr/lib/node_modules" ]; then
    echo "fix node permissions"
    chown -R $USERNAME:$USERGRP /usr/lib/node_modules
fi

#fastcgi
if [ -d "/var/lib/apache2/fastcgi" ]; then
    # fix fastcgi
    echo "fix apache fastcgi permissions"
    chown -R $USERNAME:$USERGRP /var/lib/apache2/fastcgi
fi

# APACHE
if [ -f "/etc/apache2/envvars" ]; then
    # inject new user
    echo "inject user ($USERNAME) as default apache user"
    echo "" >> /etc/apache2/envvars
    echo "# create from bootstap.sh in BOILERPLATE/provision/bootstrap.sh" >> /etc/apache2/envvars
    echo "export APACHE_RUN_USER=$USERNAME" >> /etc/apache2/envvars
    echo "export APACHE_RUN_GROUP=$USERGRP" >> /etc/apache2/envvars
fi

# NGINX
if [ -f "/etc/nginx/nginx.conf" ]; then
    echo "inject user ($USERNAME) as default nginx user"
    sed "s/user .*;/user $USERNAME;/" /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.new
    rm -rf /etc/nginx/nginx.conf
    mv /etc/nginx/nginx.conf.new /etc/nginx/nginx.conf
fi

# PHP-FPM
if [ -f "/opt/docker/etc/php/fpm/pool.d/application.conf" ]; then
    echo "inject user ($USERNAME) as default php-fpm user"
    sed "s/user = .*/user = $USERNAME/" /opt/docker/etc/php/fpm/pool.d/application.conf > /opt/docker/etc/php/fpm/pool.d/application.conf.new
    sed "s/group = .*/group = $USERGRP/" /opt/docker/etc/php/fpm/pool.d/application.conf.new > /opt/docker/etc/php/fpm/pool.d/application.conf.new2
    rm -rf /opt/docker/etc/php/fpm/pool.d/application.conf
    rm -rf /opt/docker/etc/php/fpm/pool.d/application.conf.new
    mv /opt/docker/etc/php/fpm/pool.d/application.conf.new2 /opt/docker/etc/php/fpm/pool.d/application.conf
fi