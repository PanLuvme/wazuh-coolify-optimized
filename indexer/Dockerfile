FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Wazuh Indexer
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates lsb-release \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends wazuh-indexer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Generate auto-certs to prevent crash on startup
RUN /usr/share/wazuh-indexer/bin/opensearch-security-install-demo-configuration.sh -y

RUN groupadd -g 1000 wazuh-indexer && \
    useradd -u 1000 -g 1000 -d /usr/share/wazuh-indexer -s /bin/bash wazuh-indexer && \
    chown -R wazuh-indexer:wazuh-indexer /usr/share/wazuh-indexer /etc/wazuh-indexer /var/lib/wazuh-indexer

USER wazuh-indexer
WORKDIR /usr/share/wazuh-indexer

EXPOSE 9200 9300

ENTRYPOINT ["/usr/share/wazuh-indexer/bin/opensearch"]
