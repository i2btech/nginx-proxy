#!/bin/sh

mkdir -p /mnt/data/letsencrypt
ln -s /mnt/data/letsencrypt /etc/letsencrypt

if [ -f /devops/nginx-final.conf ] ; then
    if [ -f "/etc/letsencrypt/live/proxy/fullchain.pem" ] ; then
        cp /devops/nginx-final.conf /etc/nginx/sites-enabled/
    else
        cp /devops/nginx-initial.conf /etc/nginx/sites-enabled/
    fi
fi

/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
