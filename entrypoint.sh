#!/usr/bin/env bash
# https://stackoverflow.com/questions/27669950/difference-between-euid-and-uid
set -e

APP_USER=steam
APP_GROUP=steam
APP_HOME=/home/$APP_USER
CURRENT_GID=$(getent group "$APP_GROUP" 2>/dev/null | cut -d: -f3)
CURRENT_UID=$(id -u "$APP_USER" 2>/dev/null || echo "")

if [[ "${EUID}" -ne 0 ]]; then
    echo ">>> [Entrypoint] Requires root to run setup (creating users, fixing file ownership)."
    echo "    The container process is currently running as EUID=${EUID}. Please start the container without a --user override."
    exit 1
fi

if [[ "${PUID}" -eq 0 ]] || [[ "${PGID}" -eq 0 ]]; then
    echo ">>> [Config] PUID=${PUID} PGID=${PGID} — Running the application user as root is not supported."
    echo "    This container is designed to drop privileges after setup. Please set non-zero values for PUID and PGID."
    exit 1
fi

if [[ -z "$CURRENT_GID" ]]; then
    echo "> Group '$APP_GROUP' not found — creating with GID=${PGID}"
    groupadd "$APP_GROUP" --gid "${PGID}"
elif [[ "$CURRENT_GID" -ne "${PGID}" ]]; then
    echo "> Group '$APP_GROUP' found with GID=${CURRENT_GID} — updating to GID=${PGID}"
    groupmod -g "${PGID}" "$APP_GROUP" > /dev/null
else
    echo "> Group '$APP_GROUP' found with correct GID=${PGID} — skipping"
fi

if [[ -z "$CURRENT_UID" ]]; then
    echo "> User '$APP_USER' not found — creating with UID=${PUID}"
    useradd -g "$APP_GROUP" -m -d "$APP_HOME" -s /bin/bash "$APP_USER" --uid "${PUID}"
elif [[ "$CURRENT_UID" -ne "${PUID}" ]]; then
    echo "> User '$APP_USER' found with UID=${CURRENT_UID} — updating to UID=${PUID}"
    usermod -u "${PUID}" -g "${PGID}" "$APP_USER" > /dev/null
else
    echo "> User '$APP_USER' found with correct UID=${PUID} — skipping"
fi

chown -R "$APP_USER":"$APP_GROUP" $APP_HOME

exec gosu $APP_USER:$APP_GROUP "$@"
