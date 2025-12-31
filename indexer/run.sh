#!/bin/bash
set -e

echo "Starting Wazuh Indexer..."
/usr/share/wazuh-indexer/bin/opensearch &
PID=$!

# Wait for indexer to be ready
echo "Waiting for Indexer to start..."
timeout 90 bash -c 'until curl -sk https://localhost:9200 > /dev/null 2>&1; do sleep 3; done' || {
  echo "ERROR: Indexer failed to start within 90 seconds"
  exit 1
}

echo "Indexer is up, initializing security..."

# Initialize security plugin
export JAVA_HOME=/usr/share/wazuh-indexer/jdk
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig/ \
  -icl -nhnv \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -key /etc/wazuh-indexer/certs/admin-key.pem \
  -h localhost || {
  echo "WARNING: Security initialization failed, continuing anyway..."
}

echo "Wazuh Indexer ready!"
wait $PID
