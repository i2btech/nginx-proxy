#!/bin/bash
set -e

if [ -f /devops/nginx-final.conf ] ; then

    cat /devops/nginx-final.conf | grep server_name | uniq > certbot_domains.txt
    while read line ; do
        if [ -z $CERTBOT_DOMAINS ] ; then
            CERTBOT_DOMAINS=$(echo -e "$line" | tr -s " " | cut -d " " -f 2 | cut -d ";" -f 1)
        else
            CERTBOT_DOMAINS="$CERTBOT_DOMAINS,$(echo -e "$line" | tr -s " " | cut -d " " -f 2 | cut -d ";" -f 1)"
        fi
    done < certbot_domains.txt

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
            --domain "${CERTBOT_DOMAINS}"
        sleep 3
        rm -rf /etc/nginx/sites-enabled/*
        cp /devops/nginx-final.conf /etc/nginx/sites-enabled/
        nginx -s reload
    fi
fi
