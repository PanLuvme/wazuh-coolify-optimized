FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates lsb-release openssl tar \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends wazuh-indexer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Generate Certificates 
RUN cat > /tmp/certs.sh <<EOF
#!/bin/bash
set -e
mkdir -p /etc/wazuh-indexer/certs
cd /etc/wazuh-indexer/certs

# Root CA
openssl genrsa -out root-ca.key 2048
openssl req -new -x509 -days 3650 -key root-ca.key -subj "/C=US/L=California/O=Wazuh/CN=root-ca" -out root-ca.pem

# Admin Cert
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -subj "/C=US/L=California/O=Wazuh/CN=admin" -out admin.csr
openssl x509 -req -days 3650 -in admin.csr -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -out admin.pem
cp admin.key admin-key.pem

# Indexer Node Cert
openssl genrsa -out indexer.key 2048
openssl req -new -key indexer.key -subj "/C=US/L=California/O=Wazuh/CN=wazuh-indexer" -out indexer.csr
openssl x509 -req -days 3650 -in indexer.csr -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -out indexer.pem
cp indexer.key indexer-key.pem

# Cleanup (Force flag prevents failure if files are missing)
rm -f *.csr *.srl
EOF

# Execute Script and Set Permissions
RUN chmod +x /tmp/certs.sh && /tmp/certs.sh && rm /tmp/certs.sh

RUN chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs && \
    chmod 750 /etc/wazuh-indexer/certs && \
    chmod 400 /etc/wazuh-indexer/certs/* && \
    chown -R wazuh-indexer:wazuh-indexer /usr/share/wazuh-indexer /var/lib/wazuh-indexer

USER wazuh-indexer
WORKDIR /usr/share/wazuh-indexer

EXPOSE 9200 9300

ENTRYPOINT ["/usr/share/wazuh-indexer/bin/opensearch"]
