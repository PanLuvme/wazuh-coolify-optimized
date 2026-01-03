#!/bin/bash
set -e

SECURITY_INIT_MARKER="/var/lib/wazuh-indexer/.security_initialized"
FORCE_SECURITY_INIT="${FORCE_SECURITY_INIT:-false}"

echo "Starting Wazuh Indexer..."
/usr/share/wazuh-indexer/bin/opensearch &
PID=$!

echo "Waiting for Indexer to start..."
timeout 90 bash -c 'until curl -sk https://localhost:9200 > /dev/null 2>&1; do sleep 3; done' || {
  echo "ERROR: Indexer failed to start within 90 seconds"
  exit 1
}

echo "Indexer is up, initializing security..."

SECURITY_CONFIG_DIR=""
for d in \
  "/usr/share/wazuh-indexer/config/opensearch-security" \
  "/etc/wazuh-indexer/opensearch-security" \
  "/usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig"; do
  if [[ -f "${d}/config.yml" ]]; then
    SECURITY_CONFIG_DIR="${d}"
    break
  fi
done

if [[ -z "${SECURITY_CONFIG_DIR}" ]]; then
  echo "ERROR: Could not find OpenSearch Security configuration directory (missing config.yml)."
  echo "Looked in:"
  echo "  - /usr/share/wazuh-indexer/config/opensearch-security"
  echo "  - /etc/wazuh-indexer/opensearch-security"
  echo "  - /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig"
  exit 1
fi

if [[ -f "${SECURITY_INIT_MARKER}" && "${FORCE_SECURITY_INIT}" != "true" ]]; then
  echo "Security already initialized (marker present: ${SECURITY_INIT_MARKER}). Skipping securityadmin.sh."
  echo "Set FORCE_SECURITY_INIT=true to re-apply security configuration."
else
  echo "Using security config directory: ${SECURITY_CONFIG_DIR}"

  export JAVA_HOME=/usr/share/wazuh-indexer/jdk
  for attempt in 1 2 3 4 5; do
    echo "Running securityadmin.sh (attempt ${attempt}/5)..."
    if /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
      -cd "${SECURITY_CONFIG_DIR}/" \
      -icl -nhnv \
      -cacert /etc/wazuh-indexer/certs/root-ca.pem \
      -cert /etc/wazuh-indexer/certs/admin.pem \
      -key /etc/wazuh-indexer/certs/admin-key.pem \
      -h localhost -p 9200; then
      touch "${SECURITY_INIT_MARKER}" || true
      echo "Security initialization completed."
      break
    fi
    if [[ "${attempt}" -eq 5 ]]; then
      echo "ERROR: Security initialization failed after 5 attempts."
      exit 1
    fi
    sleep 10
  done
fi

echo "Wazuh Indexer ready!"
wait $PID
