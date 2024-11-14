#!/bin/bash
set -e

if [ -f /devops/nginx-final.conf ] ; then

    cat /devops/nginx-final.conf | grep ssl_certificate_key | tr -s " " > certbot_domains.txt
    while read line ; do
        if [ -z $CERTBOT_DOMAINS ] ; then
            CERTBOT_DOMAINS=$(echo -e "$line" | tr -s " " | cut -d " " -f 2 | cut -d ";" -f 1 | cut -d "/" -f 5)
        else
            CERTBOT_DOMAINS="$CERTBOT_DOMAINS,$(echo -e "$line" | tr -s " " | cut -d " " -f 2 | cut -d ";" -f 1 | cut -d "/" -f 5)"
        fi
    done < certbot_domains.txt

    SSL_KEY=$(cat /devops/nginx-final.conf | grep ssl_certificate_key | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1 | tail -n 1)
    if [ -f $SSL_KEY ] ; then
        # if there is multiple vhost and one certificate exist, we assume all of them exist
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
            --register-unsafely-without-email \ 
            --domain "${CERTBOT_DOMAINS}"
        sleep 3
        rm -rf /etc/nginx/sites-enabled/*
        cp /devops/nginx-final.conf /etc/nginx/sites-enabled/
        nginx -s reload
    fi
fi
