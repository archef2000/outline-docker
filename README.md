# Outline Server

## Basic Configuration
### docker-compose
```
version: '3.3'
services:
    outline:
        ports:
            - '8081:8081'
            - '9999:9999'
            - '9999:9999/udp'
        environment:
            - DOMAIN=vpn.example.com
        image: archef2000/outline
```

### docker run
```
$ docker run -d \
              -p 8081:8081 \
              -p 9999:9999 \
              -p 9999:9999/udp \
              -e "DOMAIN=vpn.example.com" \
              archef2000/outline
```

# Variables
## Environment Variables
| Variable | Required | Function | Example |
|----------|----------|----------|----------|
|`DOMAIN`| Yes | Domain/IP for SS configs |`DOMAIN=vpn.example.com`|
|`CERTIFICATE_FILE`| No | Certificate file path |`CERTIFICATE_FILE="/data/server.crt"`|
|`PRIVATE_KEY_FILE`| No | Private key file path |`PRIVATE_KEY_FILE="/data/server.key"`|
|`SB_STATE_DIR`| No | Dir inside the container to store config |`SB_STATE_DIR="/data"`|
|`LOG_LEVEL`| No | Set log level for the server |`LOG_LEVEL="warn"`|
|`METRICS`| No | Enable/Disable metrics |`METRICS="false"`|
|`METRICS_URL`| No | Metrics url to send logs to |`METRICS_URL="https://prod.metrics.getoutline.org"`|
|`ACCESS_KEY_PORT`| No | Port for new client configs |`ACCESS_KEY_PORT=9999`|
|`API_PORT`| No | Port the server listens on for the Outline manager |`API_PORT=8081`|

## Volumes
| Volume | Required | Function | Example |
|----------|----------|----------|----------|
| `/data` | Yes | Outline server data | `/your/config/path/:/data`|

## Ports
| Port | Proto | Required | Function | Example |
|----------|----------|----------|----------|----------|
| `8081` | TCP | Yes | Outline API server | `8081:8081/tcp`|
| `9999` | TCP | Yes | Outline Shadowsocks server | `9999:9999/tcp`|
| `9999` | UDP | Yes | Outline Shadowsocks server | `9999:9999/udp`|

