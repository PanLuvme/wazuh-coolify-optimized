#!/usr/bin/env bash
set -euo pipefail

echo "[manager] Starting Wazuh Manager..."

INDEXER_URL="${INDEXER_URL:-https://wazuh-indexer:9200}"
INDEXER_USERNAME="${INDEXER_USERNAME:-admin}"
INDEXER_PASSWORD="${INDEXER_PASSWORD:-admin}"
FILEBEAT_SSL_VERIFICATION_MODE="${FILEBEAT_SSL_VERIFICATION_MODE:-none}"

SSL_CERTIFICATE_AUTHORITIES="${SSL_CERTIFICATE_AUTHORITIES:-}"
SSL_CERTIFICATE="${SSL_CERTIFICATE:-}"
SSL_KEY="${SSL_KEY:-}"

mkdir -p /var/ossec/logs /var/ossec/queue/rids /var/ossec/etc
touch /var/ossec/logs/ossec.log

echo "[manager] Waiting for Indexer (${INDEXER_URL}) to be reachable..."
for i in {1..60}; do
  http_code="$(curl -sk -o /dev/null -w '%{http_code}' "${INDEXER_URL}" || true)"
  if [[ "${http_code}" == "200" || "${http_code}" == "401" ]]; then
    echo "[manager] Indexer reachable (HTTP ${http_code})."
    break
  fi
  echo "[manager] Waiting for indexer... attempt ${i}/60 (last HTTP: ${http_code:-NA})"
  sleep 2
done

echo "[manager] Starting Wazuh Manager services..."
/var/ossec/bin/wazuh-control start

echo "[manager] Waiting for services to initialize..."
sleep 15

if /var/ossec/bin/wazuh-control status > /dev/null 2>&1; then
  echo "[manager] Wazuh Manager is running."
else
  echo "[manager] WARNING: Manager may not be fully started yet; continuing."
fi

if command -v filebeat > /dev/null 2>&1; then
  echo "[manager] Filebeat detected. Generating /etc/filebeat/filebeat.yml..."

  idx_scheme="https"
  idx_host="wazuh-indexer"
  idx_port="9200"
  if [[ "$INDEXER_URL" =~ ^(https?)://([^:/]+)(:([0-9]+))? ]]; then
    idx_scheme="${BASH_REMATCH[1]}"
    idx_host="${BASH_REMATCH[2]}"
    if [[ -n "${BASH_REMATCH[4]:-}" ]]; then
      idx_port="${BASH_REMATCH[4]}"
    fi
  fi

  mkdir -p /etc/filebeat

  use_wazuh_module=false
  if [[ -d "/usr/share/filebeat/module/wazuh" ]]; then
    use_wazuh_module=true
  fi

  if [[ "$use_wazuh_module" == true ]]; then
    cat > /etc/filebeat/filebeat.yml <<EOF
filebeat.modules:
  - module: wazuh
    alerts:
      enabled: true
    archives:
      enabled: false

output.elasticsearch:
  hosts: ["${idx_host}:${idx_port}"]
  protocol: ${idx_scheme}
  username: "${INDEXER_USERNAME}"
  password: "${INDEXER_PASSWORD}"
  ssl.verification_mode: ${FILEBEAT_SSL_VERIFICATION_MODE}

setup.ilm.enabled: false
EOF
  else
    cat > /etc/filebeat/filebeat.yml <<EOF
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/ossec/logs/alerts/alerts.json
    json.keys_under_root: true
    json.add_error_key: true
    json.expand_keys: true

output.elasticsearch:
  hosts: ["${idx_host}:${idx_port}"]
  protocol: ${idx_scheme}
  username: "${INDEXER_USERNAME}"
  password: "${INDEXER_PASSWORD}"
  ssl.verification_mode: ${FILEBEAT_SSL_VERIFICATION_MODE}

setup.ilm.enabled: false
EOF
  fi

  if [[ -n "$SSL_CERTIFICATE_AUTHORITIES" ]]; then
    echo "  ssl.certificate_authorities: [\"${SSL_CERTIFICATE_AUTHORITIES}\"]" >> /etc/filebeat/filebeat.yml
  fi
  if [[ -n "$SSL_CERTIFICATE" ]]; then
    echo "  ssl.certificate: \"${SSL_CERTIFICATE}\"" >> /etc/filebeat/filebeat.yml
  fi
  if [[ -n "$SSL_KEY" ]]; then
    echo "  ssl.key: \"${SSL_KEY}\"" >> /etc/filebeat/filebeat.yml
  fi

  echo "[manager] Starting Filebeat in foreground..."
  exec filebeat -e -c /etc/filebeat/filebeat.yml
else
  echo "[manager] Filebeat not found in the image. The stack may start, but you may not see alerts indexed."
  echo "[manager] Keeping container alive by tailing /var/ossec/logs/ossec.log..."
  exec tail -F /var/ossec/logs/ossec.log
fi
