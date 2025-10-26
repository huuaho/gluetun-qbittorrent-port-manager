#!/usr/bin/env bash
set -euo pipefail

COOKIES="/tmp/qb.cookie"

# Expects envs:
# QBITTORRENT_USER, QBITTORRENT_PASS, QBITTORRENT_SERVER, QBITTORRENT_PORT, HTTP_S, PORT_FORWARDED

login() {
  curl -s -c "$COOKIES" \
    -H "Referer: ${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/" \
    -H "Origin: ${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}" \
    -X POST \
    --data-urlencode "username=${QBITTORRENT_USER}" \
    --data-urlencode "password=${QBITTORRENT_PASS}" \
    "${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/auth/login" >/dev/null
}

set_listen_port() {
  local port="$1"
  curl -s -b "$COOKIES" \
    -H "Referer: ${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/" \
    -H "Origin: ${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}" \
    --data "json={\"listen_port\":${port}}" \
    "${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2/app/setPreferences" >/dev/null
}

update_port () {
  if [[ ! -f "$PORT_FORWARDED" ]]; then
    echo "Missing forwarded port file at $PORT_FORWARDED"
    return 1
  fi

  PORT="$(tr -d '\n\r' < "$PORT_FORWARDED")"
  [[ "$PORT" =~ ^[0-9]+$ ]] || { echo "Invalid port in file: $PORT"; return 1; }

  rm -f "$COOKIES"
  login
  set_listen_port "$PORT"
  rm -f "$COOKIES"
  echo "✅ Updated qBittorrent listen port to $PORT"
}

# First apply immediately, then watch for changes to the file
while true; do
  if [[ -f "$PORT_FORWARDED" ]]; then
    update_port
    inotifywait -mq -e close_write --format '%w%f' "$PORT_FORWARDED" | while read -r _; do
      update_port
    done
  else
    echo "⏳ Port file $PORT_FORWARDED not found, retrying in 10s..."
    sleep 10
  fi
done
