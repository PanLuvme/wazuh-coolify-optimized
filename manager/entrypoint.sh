#!/bin/bash
set -e

echo "Starting Wazuh Manager..."
touch /var/ossec/logs/ossec.log
exec /var/ossec/bin/wazuh-control foreground
