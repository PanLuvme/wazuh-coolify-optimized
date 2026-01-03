# Wazuh on Coolify (Oracle Cloud) – Runbook

This runbook focuses on a **reliable** single-node Wazuh deployment using the `docker-compose.yml` in this repo.

## 1) Host prerequisites

### Kernel setting (required for the Indexer/OpenSearch)
On the Docker host (your Oracle VM), set:

```bash
sudo sysctl -w vm.max_map_count=262144
```

Persist it:

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-wazuh-indexer.conf
sudo sysctl --system
```

Verify:

```bash
sysctl vm.max_map_count
```

## 2) Oracle firewall / ports

Open only what you need:

* Dashboard: `5601/tcp`
* Agent comms: `1514/tcp`
* Agent registration: `1515/tcp`

Avoid exposing:

* Indexer API: `9200/tcp`
* Wazuh API: `55000/tcp` (dashboard accesses it internally)

## 3) Coolify deployment

1. In Coolify create a new **Docker Compose** application from this repository.
2. Add environment variables from `.env.example` (recommended) or create a `.env` file.
3. Deploy.

## 4) First login / validation

* Dashboard: `http://<server-ip>:5601`
* Login uses your Indexer credentials (`INDEXER_USERNAME`/`INDEXER_PASSWORD`).

### Quick checks

```bash
docker ps
docker logs wazuh-indexer --tail 50
docker logs wazuh-manager --tail 50
docker logs wazuh-dashboard --tail 50
```

## 5) Common issues

* **Indexer won't start / keeps restarting**: check `vm.max_map_count` and available RAM.
* **Dashboard loads but no data**: ensure Filebeat is installed/starting in the manager container and can reach the indexer.
* **Wazuh app can't connect to API**: verify `WAZUH_API_*` credentials match the API users.
