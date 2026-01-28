FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    procps \
    wget \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends wazuh-manager \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Filebeat 8.x (compatible with OpenSearch 2.x)
RUN wget -qO /tmp/filebeat-8.12.0-arm64.deb https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.12.0-arm64.deb \
    && dpkg -i /tmp/filebeat-8.12.0-arm64.deb \
    && rm /tmp/filebeat-8.12.0-arm64.deb

# Configure filebeat
COPY filebeat.yml /etc/filebeat/filebeat.yml
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod 644 /etc/filebeat/filebeat.yml && \
    chown root:root /etc/filebeat/filebeat.yml

EXPOSE 1514 1515 55000
VOLUME ["/var/ossec/data", "/var/ossec/logs", "/var/ossec/etc"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
