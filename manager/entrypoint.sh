#!/bin/bash
set -e

echo "Starting Wazuh Manager..."

# Ensure directories and log file exist
mkdir -p /var/ossec/logs /var/ossec/queue/rids
touch /var/ossec/logs/ossec.log

# Wait for indexer to be fully ready
echo "Waiting for Indexer..."
sleep 10

# Start the manager
echo "Launching Wazuh Manager..."
/var/ossec/bin/wazuh-control start

# Keep container running by tailing logs
echo "Wazuh Manager started, tailing logs..."
tail -f /var/ossec/logs/ossec.log
