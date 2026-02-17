#!/usr/bin/env python3
"""
Simple Wazuh alerts shipper for OpenSearch.
Replaces Filebeat to avoid version compatibility issues.
"""
import json
import os
import time
import sys
import urllib3
from datetime import datetime, timezone

try:
    import requests
except ImportError:
    os.system("pip3 install requests")
    import requests

# Disable SSL warnings for self-signed certs
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Config from environment
INDEXER_URL   = os.environ.get("INDEXER_URL",   "https://wazuh-indexer:9200")
USERNAME      = os.environ.get("INDEXER_USERNAME", "admin")
PASSWORD      = os.environ.get("INDEXER_PASSWORD", "admin")
ALERTS_FILE   = "/var/ossec/logs/alerts/alerts.json"
BATCH_SIZE    = 50    # Send in batches
FLUSH_INTERVAL = 5   # Seconds between flushes
VERIFY_SSL    = False

def wait_for_indexer():
    print("[shipper] Waiting for OpenSearch indexer...", flush=True)
    while True:
        try:
            r = requests.get(
                f"{INDEXER_URL}/_cluster/health",
                auth=(USERNAME, PASSWORD),
                verify=VERIFY_SSL,
                timeout=5
            )
            if r.status_code in (200, 401):
                print(f"[shipper] Indexer ready (HTTP {r.status_code})", flush=True)
                return
        except Exception:
            pass
        print("[shipper] Indexer not ready, retrying in 5s...", flush=True)
        time.sleep(5)

def get_index_name():
    date = datetime.now(timezone.utc).strftime("%Y.%m.%d")
    return f"wazuh-alerts-4.x-{date}"

def send_batch(batch):
    if not batch:
        return
    index = get_index_name()
    # Build bulk request body
    bulk_body = ""
    for doc in batch:
        meta = json.dumps({"index": {"_index": index}})
        bulk_body += meta + "\n" + json.dumps(doc) + "\n"
    try:
        r = requests.post(
            f"{INDEXER_URL}/_bulk",
            data=bulk_body,
            headers={"Content-Type": "application/x-ndjson"},
            auth=(USERNAME, PASSWORD),
            verify=VERIFY_SSL,
            timeout=30
        )
        if r.status_code not in (200, 201):
            print(f"[shipper] Bulk error {r.status_code}: {r.text[:200]}", flush=True)
        else:
            resp = r.json()
            if resp.get("errors"):
                print(f"[shipper] Some docs failed to index", flush=True)
            else:
                print(f"[shipper] Sent {len(batch)} alerts to {index}", flush=True)
    except Exception as e:
        print(f"[shipper] Send error: {e}", flush=True)

def tail_alerts():
    print(f"[shipper] Tailing {ALERTS_FILE}", flush=True)
    # Wait for file to exist
    while not os.path.exists(ALERTS_FILE):
        print("[shipper] Waiting for alerts file...", flush=True)
        time.sleep(5)

    batch = []
    last_flush = time.time()

    with open(ALERTS_FILE, "r") as f:
        # Seek to end of file to only get new alerts
        f.seek(0, 2)
        print("[shipper] Listening for new alerts...", flush=True)

        while True:
            line = f.readline()
            if line:
                line = line.strip()
                if line:
                    try:
                        doc = json.loads(line)
                        batch.append(doc)
                    except json.JSONDecodeError:
                        pass

            # Flush batch if full or timeout reached
            now = time.time()
            if len(batch) >= BATCH_SIZE or (batch and now - last_flush >= FLUSH_INTERVAL):
                send_batch(batch)
                batch = []
                last_flush = now
            elif not line:
                time.sleep(0.1)

if __name__ == "__main__":
    print("[shipper] Starting Wazuh OpenSearch shipper", flush=True)
    wait_for_indexer()
    tail_alerts()
