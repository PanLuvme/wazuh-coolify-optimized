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

echo "Creating Wazuh index template..."
# Retry until indexer accepts requests (security may take a moment)
for i in {1..10}; do
  response=$(curl -sk -u admin:admin -X PUT "https://localhost:9200/_template/wazuh-alerts" \
    -H 'Content-Type: application/json' \
    -d '{
      "index_patterns": ["wazuh-alerts-*"],
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0,
        "index.refresh_interval": "5s"
      },
      "mappings": {
        "dynamic": true,
        "dynamic_templates": [
          {
            "strings_as_keywords": {
              "match_mapping_type": "string",
              "mapping": {
                "type": "keyword",
                "ignore_above": 1024
              }
            }
          }
        ],
        "properties": {
          "timestamp": {
            "type": "date",
            "format": "yyyy-MM-dd HH:mm:ss.SSS||yyyy-MM-dd||epoch_millis||strict_date_optional_time"
          },
          "rule": {
            "properties": {
              "level": { "type": "integer" },
              "id": { "type": "keyword" },
              "description": { "type": "keyword" }
            }
          },
          "agent": {
            "properties": {
              "id": { "type": "keyword" },
              "name": { "type": "keyword" },
              "ip": { "type": "ip" }
            }
          },
          "full_log": { "type": "text" },
          "location": { "type": "keyword" }
        }
      }
    }' 2>&1)

  if echo "$response" | grep -q '"acknowledged":true'; then
    echo "Wazuh index template created successfully!"
    break
  else
    echo "Template creation attempt $i/10 failed, retrying in 5s... Response: $response"
    sleep 5
  fi
done

echo "Wazuh Indexer ready!"
wait $PID
