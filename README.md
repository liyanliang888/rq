# vless + ws + tls + Cloudflare 固定隧道镜像

这个仓库提供一个单容器镜像，内置：

- **Xray-core**：提供 `VLESS + WebSocket + TLS` 入站。
- **cloudflared**：连接 Cloudflare Named Tunnel（固定隧道），把公网流量转发到容器内 Xray。

## 1. 构建

```bash
docker build -t vless-ws-tls-cf-tunnel:latest .
```

## 2. 前置条件

1. 在 Cloudflare Zero Trust 创建 **Named Tunnel**（固定隧道）。
2. 获取 tunnel UUID（`CF_TUNNEL_ID`）。
3. 下载 tunnel 凭证 JSON，挂载到容器内（默认 `/var/lib/tunnel/credentials.json`）。
4. 在 Cloudflare DNS 建立一条 `CNAME` 到该 tunnel（或在 tunnel route 中添加 hostname）。

## 3. 运行

```bash
docker run -d --name vless-cf \
  -e UUID='11111111-1111-1111-1111-111111111111' \
  -e SERVER_NAME='v.example.com' \
  -e CF_TUNNEL_ID='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' \
  -e CF_HOSTNAME='v.example.com' \
  -e WS_PATH='/vlessws' \
  -v $(pwd)/credentials.json:/var/lib/tunnel/credentials.json:ro \
  vless-ws-tls-cf-tunnel:latest
```

## 4. 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|---|---|---|---|
| `UUID` | 是 | `00000000-0000-0000-0000-000000000000` | VLESS 客户端 UUID |
| `WS_PATH` | 否 | `/vlessws` | WebSocket 路径 |
| `VLESS_PORT` | 否 | `8443` | Xray 监听端口（容器内） |
| `SERVER_NAME` | 否 | `example.com` | TLS 证书 CN / SNI |
| `CF_TUNNEL_ID` | 是 | 空 | Cloudflare Named Tunnel ID |
| `CF_CREDENTIALS_FILE` | 否 | `/var/lib/tunnel/credentials.json` | Tunnel 凭证文件路径 |
| `CF_HOSTNAME` | 是 | 空 | 对外访问域名 |
| `CF_TUNNEL_METRICS` | 否 | `0.0.0.0:2000` | cloudflared metrics 地址 |
| `XRAY_LOGLEVEL` | 否 | `warning` | Xray 日志级别 |

## 5. 客户端参数（示例）

- 协议：`vless`
- 地址：`v.example.com`
- 端口：`443`
- UUID：与 `UUID` 相同
- 传输：`ws`
- WS Path：与 `WS_PATH` 相同
- TLS：开启
- SNI：`v.example.com`

> 说明：容器会自动生成自签证书供 cloudflared 回源使用，外部 TLS 由 Cloudflare 边缘证书提供。

## 6. 安全建议

- 为 `UUID` 使用随机值。
- 将 `CF_CREDENTIALS_FILE` 以只读方式挂载。
- 结合 Cloudflare Access/WAF/IP 策略限制入口访问。
