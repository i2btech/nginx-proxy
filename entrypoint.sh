#!/bin/sh

mkdir /mnt/data/letsencrypt
ln -s /mnt/data/letsencrypt /etc/letsencrypt

if [ -f /devops/nginx-final.conf ] ; then
    SSL_KEY=$(cat /devops/nginx-final.conf | grep ssl_certificate_key | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1)
    if [ -f $SSL_KEY ] ; then
        cp /devops/nginx-final.conf /etc/nginx/sites-enabled/
    else
        cp /devops/nginx-initial.conf /etc/nginx/sites-enabled/
    fi
fi

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
