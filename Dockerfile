FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt update && \
  apt install -y --no-install-recommends \
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
COPY certbot.sh /devops/certbot.sh
COPY crontab.conf /etc/crontab
COPY entrypoint.sh /devops/entrypoint.sh
COPY supervisor.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod 755 /devops/*.sh

CMD /devops/entrypoint.sh