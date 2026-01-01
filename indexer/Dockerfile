FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates lsb-release openssl tar \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends wazuh-indexer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# CRITICAL FIX: Add Admin DN and Single-Node settings PERMANENTLY
# This runs during the build, so it stays after restarts.
RUN echo "plugins.security.authcz.admin_dn:" >> /etc/wazuh-indexer/opensearch.yml && \
    echo "  - \"CN=admin,O=Wazuh,L=California,C=US\"" >> /etc/wazuh-indexer/opensearch.yml && \
    echo "discovery.type: single-node" >> /etc/wazuh-indexer/opensearch.yml && \
    echo "plugins.security.nodes_dn:" >> /etc/wazuh-indexer/opensearch.yml && \
    echo "  - \"CN=wazuh-indexer,O=Wazuh,L=California,C=US\"" >> /etc/wazuh-indexer/opensearch.yml && \
    # Remove conflicting cluster setting if it exists
    sed -i '/cluster.initial_master_nodes/d' /etc/wazuh-indexer/opensearch.yml

COPY generate-certs.sh /usr/local/bin/generate-certs.sh
COPY run.sh /usr/local/bin/run.sh

RUN chmod +x /usr/local/bin/generate-certs.sh && \
    chmod +x /usr/local/bin/run.sh && \
    /usr/local/bin/generate-certs.sh && \
    chown -R wazuh-indexer:wazuh-indexer /usr/share/wazuh-indexer /var/lib/wazuh-indexer /etc/wazuh-indexer && \
    chown wazuh-indexer:wazuh-indexer /etc/default/wazuh-indexer

USER wazuh-indexer
WORKDIR /usr/share/wazuh-indexer

EXPOSE 9200 9300

ENTRYPOINT ["/usr/local/bin/run.sh"]
