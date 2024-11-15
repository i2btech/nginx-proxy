#!/bin/sh
# https://www.baeldung.com/linux/bash-parse-command-line-arguments
set -e

VALID_ARGS=$(getopt -o hsc --long help,startup,certbot -- "$@")
if [ $? -ne 0 ]; then
    exit 1;
fi

help() {
    cat << USAGE >&2
Usage:
    entrypoint.sh [-h] [-s] [-c]
    -h | --help     Show this message
    -s | --startup  ...
    -c | --certbot  ...
USAGE
    exit 1
}

get_domains() {
    cat /devops/nginx.conf | grep server_name | uniq > certbot_domains.txt
    while read line ; do
        if [ -z $CERTBOT_DOMAINS ] ; then
            CERTBOT_DOMAINS=$(echo -e "$line" | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1)
        else
            CERTBOT_DOMAINS="$CERTBOT_DOMAINS,$(echo -e "$line" | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1)"
        fi
    done < certbot_domains.txt
    echo $CERTBOT_DOMAINS
}

startup() {
    mkdir -p /mnt/data/letsencrypt
    ln -s /mnt/data/letsencrypt /etc/letsencrypt

    if [ -f "/etc/letsencrypt/live/proxy/fullchain.pem" ] ; then
        cp /devops/nginx.conf /etc/nginx/sites-enabled/
    else
        rm -f /etc/nginx/sites-enabled/nginx-initial.conf
        for D in $(echo $(get_domains) | tr -t "," "\n") ; do
            echo $D
            echo "server {" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "listen 80;" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "server_name ${D};" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "root /var/www/html;" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "}" >> /etc/nginx/sites-enabled/nginx-initial.conf
        done
    fi

    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
}

certbot() {
    if [ -f "/etc/letsencrypt/live/proxy/fullchain.pem" ] ; then
        echo "key found" > /devops/certbot.log
        exit 1
    else
        echo "key NOT found" > /devops/certbot.log
        certbot certonly \
            --cert-name proxy \
            --nginx \
            --non-interactive \
            --agree-tos \
            --no-eff-email \
            --no-redirect \
            --register-unsafely-without-email \
            --domain "$(get_domains)"
        sleep 3
        rm -rf /etc/nginx/sites-enabled/*
        cp /devops/nginx.conf /etc/nginx/sites-enabled/
        nginx -s reload
    fi
}

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -h | --help)
        help
        shift
        ;;
    -s | --startup)
        startup
        shift
        ;;
    -c | --certbot)
        certbot
        shift
        ;;
    --) shift; 
        break 
        ;;
  esac
done
