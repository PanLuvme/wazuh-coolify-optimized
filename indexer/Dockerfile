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

RUN cat > /tmp/certs.sh <<EOF
#!/bin/bash
set -e
mkdir -p /etc/wazuh-indexer/certs
cd /etc/wazuh-indexer/certs
openssl genrsa -out root-ca.key 2048
openssl req -new -x509 -days 3650 -key root-ca.key -subj "/C=US/L=California/O=Wazuh/CN=root-ca" -out root-ca.pem
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -subj "/C=US/L=California/O=Wazuh/CN=admin" -out admin.csr
openssl x509 -req -days 3650 -in admin.csr -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -out admin.pem
cp admin.key admin-key.pem
openssl genrsa -out indexer.key 2048
openssl req -new -key indexer.key -subj "/C=US/L=California/O=Wazuh/CN=wazuh-indexer" -out indexer.csr
openssl x509 -req -days 3650 -in indexer.csr -CA root-ca.pem -CAkey root-ca.key -CAcreateserial -out indexer.pem
cp indexer.key indexer-key.pem
rm -f *.csr *.srl
EOF

RUN chmod +x /tmp/certs.sh && /tmp/certs.sh && rm /tmp/certs.sh

RUN chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs && \
    chmod 750 /etc/wazuh-indexer/certs && \
    chmod 400 /etc/wazuh-indexer/certs/* && \
    chown -R wazuh-indexer:wazuh-indexer /usr/share/wazuh-indexer /var/lib/wazuh-indexer && \
    chown wazuh-indexer:wazuh-indexer /etc/default/wazuh-indexer

RUN cat > /entrypoint.sh <<'EOF'
#!/bin/bash
/usr/share/wazuh-indexer/bin/opensearch &
PID=$!
echo "Waiting for Indexer to start..."
timeout 60 bash -c "until curl -s -k https://localhost:9200 > /dev/null; do sleep 5; done"
echo "Running Security Initialization..."
export JAVA_HOME=/usr/share/wazuh-indexer/jdk
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig/ \
  -icl -nhnv \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -key /etc/wazuh-indexer/certs/admin-key.pem \
  -h localhost
wait $PID
EOF

RUN chmod +x /entrypoint.sh

USER wazuh-indexer
WORKDIR /usr/share/wazuh-indexer

EXPOSE 9200 9300

ENTRYPOINT ["/entrypoint.sh"]
