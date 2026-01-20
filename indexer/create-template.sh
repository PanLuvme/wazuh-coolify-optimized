#!/bin/bash
set -e

echo "Waiting for indexer to be ready..."
until curl -sk -u admin:admin https://localhost:9200/_cluster/health > /dev/null 2>&1; do
  sleep 5
done

echo "Creating Wazuh alerts index template..."
curl -sk -u admin:admin -X PUT "https://localhost:9200/_index_template/wazuh-alerts" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["wazuh-alerts-*"],
  "priority": 1,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.mapping.total_fields.limit": 10000
    },
    "mappings": {
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
        "@timestamp": {"type": "date"},
        "timestamp": {"type": "date"}
      }
    }
  }
}'

echo ""
echo "Template created successfully!"
