FROM alpine:3.20

ARG XRAY_VERSION=1.8.24
ARG CLOUDFLARED_VERSION=2026.3.1

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    openssl \
    tzdata \
    gettext \
    libc6-compat \
    unzip \
    && update-ca-certificates

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64) xray_arch='64'; cloudflared_arch='amd64' ;; \
      aarch64) xray_arch='arm64-v8a'; cloudflared_arch='arm64' ;; \
      *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${xray_arch}.zip"; \
    unzip -q /tmp/xray.zip -d /tmp/xray; \
    install -m 0755 /tmp/xray/xray /usr/local/bin/xray; \
    curl -fsSL -o /usr/local/bin/cloudflared "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${cloudflared_arch}"; \
    chmod +x /usr/local/bin/cloudflared; \
    rm -rf /tmp/xray.zip /tmp/xray

RUN adduser -D -H -s /sbin/nologin app && \
    mkdir -p /etc/xray /etc/cloudflared /var/lib/tunnel /var/log/app && \
    chown -R app:app /etc/xray /etc/cloudflared /var/lib/tunnel /var/log/app

COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/xray-config.json.tpl /templates/xray-config.json.tpl
COPY docker/cloudflared-config.yml.tpl /templates/cloudflared-config.yml.tpl
RUN chmod +x /entrypoint.sh

ENV UUID="00000000-0000-0000-0000-000000000000" \
    WS_PATH="/vlessws" \
    VLESS_PORT="8443" \
    SERVER_NAME="example.com" \
    CF_TUNNEL_ID="" \
    CF_CREDENTIALS_FILE="/var/lib/tunnel/credentials.json" \
    CF_HOSTNAME="" \
    CF_TUNNEL_METRICS="0.0.0.0:2000" \
    XRAY_LOGLEVEL="warning"

USER app
EXPOSE 8443
ENTRYPOINT ["/entrypoint.sh"]
