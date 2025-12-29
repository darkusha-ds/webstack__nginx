FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    ca-certificates \
    curl \
    bash \
    certbot \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/certbot

COPY webstack_nginx/certbot/ /opt/certbot/
RUN chmod +x /opt/certbot/*.sh

COPY webstack_nginx/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 443
CMD ["/start.sh"]