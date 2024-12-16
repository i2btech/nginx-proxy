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
    cron && \
  apt clean && \
  apt autoremove --purge

RUN \
  pip install certbot certbot-nginx --break-system-packages && \
  pip cache purge

RUN mkdir -p /devops
COPY crontab.conf /etc/crontab
COPY entrypoint.sh /devops/entrypoint.sh
COPY supervisor-*.conf /etc/supervisor/conf.d/

RUN chmod 755 /devops/*.sh

ENTRYPOINT ["/devops/entrypoint.sh"]
CMD ["-r"]
