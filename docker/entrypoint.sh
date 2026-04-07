#!/usr/bin/env bash
set -euo pipefail

: "${UUID:?UUID is required}"
: "${CF_TUNNEL_ID:?CF_TUNNEL_ID is required}"
: "${CF_HOSTNAME:?CF_HOSTNAME is required}"

if [[ ! -f "${CF_CREDENTIALS_FILE}" ]]; then
  echo "cloudflared credentials file not found: ${CF_CREDENTIALS_FILE}" >&2
  exit 1
fi

mkdir -p /etc/xray /etc/cloudflared /var/lib/tunnel

if [[ ! -f /etc/xray/server.crt || ! -f /etc/xray/server.key ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout /etc/xray/server.key \
    -out /etc/xray/server.crt \
    -subj "/CN=${SERVER_NAME}" >/dev/null 2>&1
fi

export UUID WS_PATH VLESS_PORT SERVER_NAME XRAY_LOGLEVEL
export CF_TUNNEL_ID CF_CREDENTIALS_FILE CF_HOSTNAME CF_TUNNEL_METRICS

envsubst < /templates/xray-config.json.tpl > /etc/xray/config.json
envsubst < /templates/cloudflared-config.yml.tpl > /etc/cloudflared/config.yml

xray run -c /etc/xray/config.json &
XRAY_PID=$!

cloudflared tunnel --config /etc/cloudflared/config.yml run &
CF_PID=$!

cleanup() {
  kill -TERM "${XRAY_PID}" "${CF_PID}" 2>/dev/null || true
  wait "${XRAY_PID}" "${CF_PID}" 2>/dev/null || true
}

trap cleanup SIGINT SIGTERM
wait -n "${XRAY_PID}" "${CF_PID}"
cleanup
