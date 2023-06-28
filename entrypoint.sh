#!/bin/sh
STATE_CONFIG="${SB_STATE_DIR}/shadowbox_server_config.json"
ACCESS_CONFIG="${SB_STATE_DIR}/access.txt"

get_config() {
    cat "${STATE_CONFIG}" | jq -r -e ".$1"
}

safe_base64() {
  url_safe="$(base64 -w 0 - | tr '/+' '_-')"
  echo -n "${url_safe%%=*}"
}

export SB_PUBLIC_IP="${DOMAIN:-$(curl --silent https://ipinfo.io/ip)}"
export SB_API_PORT="${API_PORT:-9999}"
export SB_METRICS="${METRICS:-"false"}"
export SB_METRICS_URL="${METRICS_URL:-https://prod.metrics.getoutline.org}"
export SB_CERTIFICATE_FILE="${CERTIFICATE_FILE:-"/data/server.crt"}"
export SB_PRIVATE_KEY_FILE="${PRIVATE_KEY_FILE:-"/data/server.key"}"

if [[ "${SB_METRICS}" == "true" ]]
then
    SB_METRICS="false"
    SB_METRICS_URL=""
fi

if [[ -f "${ACCESS_CONFIG}" ]]
then
    export SB_API_PREFIX="$(cat "${ACCESS_CONFIG}")"
else
    export SB_API_PREFIX="${API_PREFIX:-$(head -c 16 /dev/urandom | safe_base64)}"
    echo "${SB_API_PREFIX}" > "${ACCESS_CONFIG}"
fi

if [[ -f "${STATE_CONFIG}" ]]
then
    server_id=$(get_config 'serverId')
    create_time=$(get_config 'createdTimestampMs')
    echo "{\"serverId\":\"${server_id}\",\"metricsEnabled\":${SB_METRICS},\"createdTimestampMs\":${create_time},\"hostname\":\"${SB_PUBLIC_IP}\",\"portForNewAccessKeys\":${ACCESS_KEY_PORT}}" > "${STATE_CONFIG}"
else
    echo "{\"hostname\": \"${DOMAIN}\", \"portForNewAccessKeys\": ${ACCESS_KEY_PORT}}" > "${STATE_CONFIG}"
fi

if [ ! -f "${PRIVATE_KEY_FILE}" ] && [ ! -f "${CERTIFICATE_FILE}" ]
then
    openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -subj "/CN=${SB_PUBLIC_IP}" -keyout "${PRIVATE_KEY_FILE}" -out "${CERTIFICATE_FILE}"
fi

CERT_OPENSSL_FINGERPRINT="$(openssl x509 -noout -fingerprint -sha256 -inform pem -in ${SB_CERTIFICATE_FILE} )"
CERT_OPENSSL_FINGERPRINT="$(echo "${CERT_OPENSSL_FINGERPRINT#*=}" | tr -d :)"

echo ":::Outline Manager: {\"apiUrl\": \"https://${SB_PUBLIC_IP}:${SB_API_PORT}/${SB_API_PREFIX}\",\"certSha256\": \"$CERT_OPENSSL_FINGERPRINT\" }"

umask 0007
ulimit -n 32768
crond

node app/main.js
