#!/bin/bash
set -e

APP_USER=steam
APP_GROUP=steam
APP_HOME=/home/$APP_USER

if ! getent group $APP_GROUP > /dev/null 2>&1; then
    echo "NOT found a group, creating it"
    groupadd $APP_GROUP --gid $PGID
else
    echo "Found group $APP_GROUP"
fi
if ! getent passwd $APP_USER > /dev/null 2>&1; then
    echo "NOT found a user, creating it"
    useradd -g $APP_GROUP -m -d /home/$APP_USER -s /bin/bash $APP_USER --uid $PUID
else
    echo "Found user $APP_USER"
fi

chown -R "$APP_USER":"$APP_GROUP" $APP_HOME
exec gosu $APP_USER:$APP_GROUP "$@"
