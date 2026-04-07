tunnel: ${CF_TUNNEL_ID}
credentials-file: ${CF_CREDENTIALS_FILE}
metrics: ${CF_TUNNEL_METRICS}

ingress:
  - hostname: ${CF_HOSTNAME}
    service: https://127.0.0.1:${VLESS_PORT}
    originRequest:
      noTLSVerify: true
      http2Origin: true
  - service: http_status:404
