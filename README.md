![logo](https://i.postimg.cc/7h78tQ4f/wazuhxcoolify.png)

A custom, resource-efficient implementation of the **Wazuh Security Information and Event Management (SIEM)** system, specifically engineered for self-hosted environments like **Coolify** and **Docker**.

## 🏗️ Architecture
This stack deploys the three core Wazuh components:
1.  **Wazuh Indexer:** The highly scalable search and analytics engine (OpenSearch derivative).
2.  **Wazuh Server (Manager):** The analysis engine that processes agent data.
3.  **Wazuh Dashboard:** The web user interface for data visualization and threat hunting.

## 🛠️ Usage
Once deployed, the Wazuh Dashboard is accessible via port `5601`.

### Default credentials (first boot)
This stack uses the Indexer (OpenSearch) security users for the Dashboard login.

* **Dashboard username:** value of `INDEXER_USERNAME` (default: `admin`)
* **Dashboard password:** value of `INDEXER_PASSWORD` (default: `admin`)

The Wazuh app inside the Dashboard connects to the Wazuh server API using:

* **Wazuh API username:** value of `WAZUH_API_USERNAME` (default: `wazuh-wui`)
* **Wazuh API password:** value of `WAZUH_API_PASSWORD` (default: `wazuh-wui`)

See `.env.example`.

## 🔧 Technical Details
* **Base OS:** Ubuntu 22.04 LTS
* **Orchestration:** Docker Compose v3.8
* **SSL:** Auto-generated self-signed certificates for internal node communication.

---

*Disclaimer: This project is intended for educational, research, and homelab environments.*
