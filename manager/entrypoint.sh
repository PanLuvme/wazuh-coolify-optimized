#!/usr/bin/env bash
set -euo pipefail

echo "[manager] Starting Wazuh Manager..."

INDEXER_URL="${INDEXER_URL:-https://wazuh-indexer:9200}"
INDEXER_USERNAME="${INDEXER_USERNAME:-admin}"
INDEXER_PASSWORD="${INDEXER_PASSWORD:-admin}"

# Ensure directories exist
mkdir -p /var/ossec/logs /var/ossec/queue/rids /var/ossec/etc
touch /var/ossec/logs/ossec.log

# Wait for Indexer
echo "[manager] Waiting for Indexer (${INDEXER_URL}) to be reachable..."
for i in {1..60}; do
  http_code="$(curl -sk -o /dev/null -w '%{http_code}' "${INDEXER_URL}" || true)"
  if [[ "${http_code}" == "200" || "${http_code}" == "401" ]]; then
    echo "[manager] Indexer reachable (HTTP ${http_code})."
    break
  fi
  echo "[manager] Waiting... attempt ${i}/60 (HTTP: ${http_code:-NA})"
  sleep 2
done

# Start Wazuh Manager
echo "[manager] Starting Wazuh Manager services..."
/var/ossec/bin/wazuh-control start

echo "[manager] Waiting for services to initialize..."
sleep 15

if /var/ossec/bin/wazuh-control status > /dev/null 2>&1; then
  echo "[manager] Wazuh Manager is running."
else
  echo "[manager] WARNING: Manager may not be fully started yet."
fi

# Start Python shipper instead of Filebeat
echo "[manager] Starting OpenSearch alert shipper..."
INDEXER_URL="${INDEXER_URL}" \
INDEXER_USERNAME="${INDEXER_USERNAME}" \
INDEXER_PASSWORD="${INDEXER_PASSWORD}" \
python3 /usr/local/bin/shipper.py &

SHIPPER_PID=$!
echo "[manager] Shipper started (PID: ${SHIPPER_PID})"

# Keep container alive
echo "[manager] Tailing manager logs..."
exec tail -F /var/ossec/logs/ossec.log
