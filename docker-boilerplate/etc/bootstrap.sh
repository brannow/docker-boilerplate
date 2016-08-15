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
    useradd --uid $USERID --gid $GRPID $ANONUSER
    USERNAME=$ANONUSER
    echo "create new user ($USERID:$USERNAME) with group ($GRPID:$USERGRP)"
fi

echo "set working user to $USERNAME:$USERGRP"

######
# change apache user
######

# fix fastcgi
echo "fix fastcgi permissions"
chown -R $USERNAME:$USERGRP /var/lib/apache2/fastcgi
# inject new user
echo "inject user as default apache user"
echo "" >> /etc/apache2/envvars
echo "# IGNORE FIRST USER SET USE this --" >> /etc/apache2/envvars
echo "# create from bootstap.sh in BOILERPLATE/provision/bootstrap.sh" >> /etc/apache2/envvars
echo "export APACHE_RUN_USER=$USERNAME" >> /etc/apache2/envvars
echo "export APACHE_RUN_GROUP=$USERGRP" >> /etc/apache2/envvars