#!/bin/bash
set -e

echo "Starting Wazuh Manager..."

# Ensure directories exist
mkdir -p /var/ossec/logs /var/ossec/queue/rids /var/ossec/etc
touch /var/ossec/logs/ossec.log

# Wait for indexer
echo "Waiting for Indexer to be ready..."
for i in {1..30}; do
  if curl -sk https://wazuh-indexer:9200/_cluster/health > /dev/null 2>&1; then
    echo "Indexer is ready!"
    break
  fi
  echo "Waiting for indexer... attempt $i/30"
  sleep 2
done

# Start manager
echo "Starting Wazuh Manager services..."
/var/ossec/bin/wazuh-control start

# Wait for services to initialize
echo "Waiting for services to initialize..."
sleep 15

# Verify it started
if /var/ossec/bin/wazuh-control status > /dev/null 2>&1; then
  echo "Wazuh Manager is running!"
else
  echo "WARNING: Manager may not be fully started yet"
fi

# Keep container alive
echo "Tailing logs..."
tail -f /var/ossec/logs/ossec.log
