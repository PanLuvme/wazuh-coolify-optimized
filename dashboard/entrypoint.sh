#!/usr/bin/env bash
set -euo pipefail


SERVER_HOST="${SERVER_HOST:-0.0.0.0}"
SERVER_PORT="${SERVER_PORT:-5601}"

INDEXER_URL="${INDEXER_URL:-${OPENSEARCH_HOSTS:-https://wazuh-indexer:9200}}"
INDEXER_USERNAME="${INDEXER_USERNAME:-admin}"
INDEXER_PASSWORD="${INDEXER_PASSWORD:-admin}"

WAZUH_API_URL="${WAZUH_API_URL:-https://wazuh-manager:55000}"
WAZUH_API_USERNAME="${WAZUH_API_USERNAME:-wazuh-wui}"
WAZUH_API_PASSWORD="${WAZUH_API_PASSWORD:-wazuh-wui}"

OPENSEARCH_SSL_VERIFICATION_MODE="${OPENSEARCH_SSL_VERIFICATION_MODE:-none}"

api_scheme="https"
api_host="wazuh-manager"
api_port="55000"

if [[ "$WAZUH_API_URL" =~ ^(https?)://([^:/]+)(:([0-9]+))? ]]; then
  api_scheme="${BASH_REMATCH[1]}"
  api_host="${BASH_REMATCH[2]}"
  if [[ -n "${BASH_REMATCH[4]:-}" ]]; then
    api_port="${BASH_REMATCH[4]}"
  fi
fi

echo "[dashboard] Writing OpenSearch Dashboards config..."
cat > /etc/wazuh-dashboard/opensearch_dashboards.yml <<EOF
server.host: "${SERVER_HOST}"
server.port: ${SERVER_PORT}

server.ssl.enabled: false

opensearch.hosts: ["${INDEXER_URL}"]
opensearch.username: "${INDEXER_USERNAME}"
opensearch.password: "${INDEXER_PASSWORD}"
opensearch.ssl.verificationMode: ${OPENSEARCH_SSL_VERIFICATION_MODE}

opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
opensearch_security.multitenancy.enabled: true
opensearch_security.multitenancy.tenants.preferred: ["Private","Global"]
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
EOF

echo "[dashboard] Writing Wazuh app config..."
mkdir -p /usr/share/wazuh-dashboard/data/wazuh/config

cat > /usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml <<EOF
hosts:
  - default:
      url: ${api_scheme}://${api_host}
      port: ${api_port}
      username: ${WAZUH_API_USERNAME}
      password: ${WAZUH_API_PASSWORD}
      run_as: false
EOF

echo "[dashboard] Starting Wazuh Dashboard..."
exec /usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /etc/wazuh-dashboard/opensearch_dashboards.yml
