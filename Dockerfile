FROM alpine:latest

RUN apk add --no-cache curl inotify-tools bash

ENV QBITTORRENT_SERVER=127.0.0.1 \
    QBITTORRENT_PORT=8080 \
    QBITTORRENT_USER=admin \
    QBITTORRENT_PASS=adminadmin \
    PORT_FORWARDED=/tmp/gluetun/forwarded_port \
    HTTP_S=http

WORKDIR /app
COPY start.sh .
RUN chmod +x start.sh
CMD ["./start.sh"]
