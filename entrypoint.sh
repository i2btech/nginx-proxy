#!/bin/sh
# https://www.baeldung.com/linux/bash-parse-command-line-arguments
set -e

VALID_ARGS=$(getopt -o hrlc --long help,startup_remote,startup_local,certbot -- "$@")
if [ $? -ne 0 ]; then
    exit 1;
fi

help() {
    cat << USAGE >&2
Usage:
    entrypoint.sh [-h] [-s] [-c]
    -h | --help           Show this message
    -r | --startup_remote ...
    -l | --startup_local  ...
    -c | --certbot        ...
USAGE
    exit 1
}

get_domains() {
    cat /devops/nginx-vhost.conf | grep server_name | uniq > certbot_domains.txt
    while read line ; do
        if [ -z $CERTBOT_DOMAINS ] ; then
            CERTBOT_DOMAINS=$(echo -e "$line" | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1)
        else
            CERTBOT_DOMAINS="$CERTBOT_DOMAINS,$(echo -e "$line" | tr -s " " | cut -d " " -f 3 | cut -d ";" -f 1)"
        fi
    done < certbot_domains.txt
    echo $CERTBOT_DOMAINS
}

copy_nginx_conf() {
    rm -rf /etc/nginx/sites-enabled/*
    cp /devops/nginx-main.conf /etc/nginx/nginx.conf
    export NGINX_HTTP_PORT="${NGINX_HTTP_PORT:-80}"
    export NGINX_HTTPS_PORT="${NGINX_HTTPS_PORT:-443}"
    export NGINX_BACKEND="${NGINX_BACKEND:-localhost}"
    echo "*** Using variables:"
    echo "* NGINX_HTTP_PORT: ${NGINX_HTTP_PORT}"
    echo "* NGINX_HTTPS_PORT: ${NGINX_HTTPS_PORT}"
    echo "* NGINX_BACKEND: ${NGINX_BACKEND}"
    envsubst '$NGINX_HTTP_PORT $NGINX_HTTPS_PORT $NGINX_BACKEND' < /devops/nginx-vhost.conf > /etc/nginx/sites-enabled/nginx-vhost.conf

    echo ":)" > /var/www/html/index.html
}

# this run the proxy on a remote machine that is expose to internet
# if the certificate don't exist a custom nginx config is created to allow the execution of let's encrypt
# supervisor run nginx and the function certbot_config to generate the certificates and reload the nginx config
startup_remote() {

    cp /etc/supervisor/conf.d/supervisor-remote.conf /etc/supervisor/conf.d/supervisord-env.conf

    mkdir -p /mnt/data/letsencrypt
    ln -s /mnt/data/letsencrypt /etc/letsencrypt

    if [ -f "/etc/letsencrypt/live/proxy/fullchain.pem" ] ; then
        copy_nginx_conf
    else
        rm -rf /etc/nginx/sites-enabled/*
        for D in $(echo $(get_domains) | tr -t "," "\n") ; do
            echo $D
            echo "server {" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "listen 80;" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "server_name ${D};" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "root /var/www/html;" >> /etc/nginx/sites-enabled/nginx-initial.conf
            echo "}" >> /etc/nginx/sites-enabled/nginx-initial.conf
        done
    fi

    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor-main.conf
}

certbot_config() {
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
        copy_nginx_conf
        nginx -s reload
    fi
}

# this run the proxy on a local o remote machine
# we use a selfsigned certificate
startup_local() {

    cp /etc/supervisor/conf.d/supervisor-local.conf /etc/supervisor/conf.d/supervisord-env.conf

    mkdir -p /mnt/data/letsencrypt
    ln -s /mnt/data/letsencrypt /etc/letsencrypt

    mkdir -p /etc/letsencrypt/live/proxy/
    echo "*** Check if SSL cert exists"
    if [ ! -f /etc/nginx/ssl/ssl.crt ] ; then
        echo "*** Create default SSL cert"
        openssl req \
            -subj "/C=CL/ST=Santiago/L=Santiago/O=Company Name/OU=Org/CN=localhost" \
            -new -newkey rsa:2048 \
            -sha256 \
            -days 365 \
            -nodes \
            -x509 \
            -keyout /etc/letsencrypt/live/proxy/privkey.pem \
            -out /etc/letsencrypt/live/proxy/fullchain.pem
    fi
    copy_nginx_conf

    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor-main.conf
}

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -h | --help)
        help
        shift
        ;;
    -r | --startup-remote)
        startup_remote
        shift
        ;;
    -l | --startup-local)
        startup_local
        shift
        ;;
    -c | --certbot)
        certbot_config
        shift
        ;;
    --) shift; 
        break 
        ;;
  esac
done
