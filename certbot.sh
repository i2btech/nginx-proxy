#!/bin/bash
set -e

if [ -f /devops/nginx-final.conf ] ; then
    SSL_KEY=$(cat /devops/nginx-final.conf | grep ssl_certificate_key | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1)
    if [ -f $SSL_KEY ] ; then
        echo "key found" > /devops/certbot.log
        exit 1
    else
        echo "key NOT found" > /devops/certbot.log
        certbot certonly \
            --nginx \
            --non-interactive \
            --agree-tos \
            --no-eff-email \
            --no-redirect \
            --email "${CERTBOT_EMAIL}" \
            --domain "${CERTBOT_DOMAINS}"
        sleep 3
        rm -rf /etc/nginx/sites-enabled/*
        cp /devops/nginx-final.conf /etc/nginx/sites-enabled/
        nginx -s reload
    fi
fi
