FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt update && \
  apt install -y --no-install-recommends \
    nano \
    python3 \
    python3-pip \
    curl \
    nginx \
    supervisor \
    gettext && \
  apt clean && \
  apt autoremove --purge

RUN \
  pip install certbot certbot-nginx --break-system-packages && \
  pip cache purge

RUN mkdir -p /devops
COPY entrypoint.sh /devops/entrypoint.sh
COPY supervisor-*.conf /etc/supervisor/conf.d/
COPY nginx-main.conf /devops/nginx-main.conf
COPY nginx-vhost.conf /devops/nginx-vhost.conf
RUN chmod 755 /devops/*.sh

ENTRYPOINT ["/devops/entrypoint.sh"]
CMD ["-l"]
