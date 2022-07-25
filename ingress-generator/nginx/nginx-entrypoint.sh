#!/bin/bash

# Default
NGINX_BINARY="nginx"
CERBOT_MAIL_USE="${CERBOT_MAIL:-"support@***REMOVED***"}"
DATE_STR=$(date '+%Y-%m-%d')

# Check for debug flag
if [ "$NGINX_DEBUG" = "yes" ]; then
    echo "Running nginx in debug mode!"
    NGINX_BINARY="nginx-debug"
fi

if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    exec 3>&1
else
    exec 3>/dev/null
fi

if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
    echo >&3 "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

    echo >&3 "$0: Looking for shell scripts in /docker-entrypoint.d/"
    find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
        case "$f" in
        *.sh)
            if [ -x "$f" ]; then
                echo >&3 "$0: Launching $f"
                "$f"
            else
                # warn on shell scripts without exec bit
                echo >&3 "$0: Ignoring $f, not executable"
            fi
            ;;
        *) echo >&3 "$0: Ignoring $f" ;;
        esac
    done

    echo >&3 "$0: Configuration complete; ready for start up"
else
    echo >&3 "$0: No files found in /docker-entrypoint.d/, skipping configuration"
fi

# Copy dummy certs again if volume overlays files
mkdir -p /etc/letsencrypt/live/certs
mkdir -p /etc/letsencrypt/old-states
mkdir -p /var/www/_letsencrypt
if [ ! -f "/etc/letsencrypt/live/certs/fullchain.pem" ]; then
    cp /etc/nginx/ssl/dummy/fullchain.pem /etc/letsencrypt/live/certs/fullchain.pem
    echo "Creating dummy certs"
    echo "Dummy Certs" >/etc/letsencrypt/live/certs/dummy-marker.txt
fi
if [ ! -f "/etc/letsencrypt/live/certs/privkey.pem" ]; then
    cp /etc/nginx/ssl/dummy/privkey.pem /etc/letsencrypt/live/certs/privkey.pem
    echo "Creating dummy certs"
    echo "Dummy Certs" >/etc/letsencrypt/live/certs/dummy-marker.txt
fi

if [ $RUN_CERTBOT = "yes" ]; then
    # Check if domains are given
    if [ -z "${CERTBOT_DOMAINS}" ]; then
        echo "No domains for certbot provided. Exit"
        exit 1
    fi

    # Check if domain save file exist
    if [ ! -f /etc/letsencrypt/live/certs/domain-list.txt ]; then
        echo -n "${CERTBOT_DOMAINS}" > /etc/letsencrypt/live/certs/domain-list.txt
    fi

    if [ $(</etc/letsencrypt/live/certs/domain-list.txt) != "$CERTBOT_DOMAINS" ]; then
        echo -e "Domain list has changed!\nWill remove old certs and generate new owns..."
        echo "Dummy Certs" > /etc/letsencrypt/live/certs/dummy-marker.txt
    fi

    if [ -f "/etc/letsencrypt/live/certs/dummy-marker.txt" ]; then
        echo "Found dummy-certs! Running certbot"

        if [ $CERTBOT_STAGING = "yes" ]; then
            CERTBOT_EXTRA_ARGS="--test-cert ${CERTBOT_EXTRA_ARGS}"
            echo "Using certbot staging server"
        fi

        sleep 10s
        # Archive and remove old stuff
        tar -cvzf /etc/letsencrypt/$DATE_STR-letsencrypt-state.tar.gz --exclude="/etc/letsencrypt/old-states" /etc/letsencrypt/*
        rm -rf accounts archive cli.ini csr keys live renewal renewal-hooks
        mkdir -p /etc/letsencrypt/live/certs

        # Create new cert
        certbot certonly --webroot --webroot-path /var/www/_letsencrypt/ \
            --non-interactive -m $CERBOT_MAIL_USE --agree-tos \
            --cert-name certs -d $CERTBOT_DOMAINS $CERTBOT_EXTRA_ARGS
        nginx -t && nginx -s reload

    fi && while true; do
        certbot renew --post-hook "nginx -t && nginx -s reload"
        sleep 14d
    done &

fi

# Start main
echo "Running: ${NGINX_BINARY} -g \"daemon off;\""
exec ${NGINX_BINARY} -g "daemon off;"
