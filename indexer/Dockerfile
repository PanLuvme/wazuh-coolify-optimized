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

COPY generate-certs.sh /usr/local/bin/generate-certs.sh
COPY run.sh /usr/local/bin/run.sh
COPY create-template.sh /usr/local/bin/create-template.sh

RUN chmod +x /usr/local/bin/generate-certs.sh && \
    chmod +x /usr/local/bin/run.sh && \
    chmod +x /usr/local/bin/create-template.sh && \
    /usr/local/bin/generate-certs.sh

RUN cat > /etc/wazuh-indexer/opensearch.yml <<EOF
network.host: 0.0.0.0
node.name: node-1
discovery.seed_hosts: []
discovery.type: single-node
plugins.security.ssl.transport.pemcert_filepath: /etc/wazuh-indexer/certs/indexer.pem
plugins.security.ssl.transport.pemkey_filepath: /etc/wazuh-indexer/certs/indexer-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: /etc/wazuh-indexer/certs/indexer.pem
plugins.security.ssl.http.pemkey_filepath: /etc/wazuh-indexer/certs/indexer-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: /etc/wazuh-indexer/certs/root-ca.pem
plugins.security.allow_unsafe_democertificates: true
plugins.security.allow_default_init_securityindex: true
plugins.security.authcz.admin_dn:
  - "CN=admin,O=Wazuh,L=California,C=US"
plugins.security.nodes_dn:
  - "CN=wazuh-indexer,O=Wazuh,L=California,C=US"
EOF

RUN chown -R wazuh-indexer:wazuh-indexer /usr/share/wazuh-indexer /var/lib/wazuh-indexer /etc/wazuh-indexer && \
    chown wazuh-indexer:wazuh-indexer /etc/default/wazuh-indexer

USER wazuh-indexer
WORKDIR /usr/share/wazuh-indexer

EXPOSE 9200 9300

ENTRYPOINT ["/usr/local/bin/run.sh"]
