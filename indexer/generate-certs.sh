#!/bin/bash
set -e

mkdir -p /etc/wazuh-indexer/certs
cd /etc/wazuh-indexer/certs

openssl genrsa -out root-ca.key 2048
openssl req -new -x509 -days 3650 -key root-ca.key \
  -subj "/C=US/L=California/O=Wazuh/CN=root-ca" \
  -out root-ca.pem

openssl genrsa -out admin.key 2048
openssl req -new -key admin.key \
  -subj "/C=US/L=California/O=Wazuh/CN=admin" \
  -out admin.csr
openssl x509 -req -days 3650 -in admin.csr \
  -CA root-ca.pem -CAkey root-ca.key -CAcreateserial \
  -out admin.pem
cp admin.key admin-key.pem

openssl genrsa -out indexer.key 2048
openssl req -new -key indexer.key \
  -subj "/C=US/L=California/O=Wazuh/CN=wazuh-indexer" \
  -out indexer.csr
openssl x509 -req -days 3650 -in indexer.csr \
  -CA root-ca.pem -CAkey root-ca.key -CAcreateserial \
  -out indexer.pem
cp indexer.key indexer-key.pem

rm -f *.csr *.srl

chmod 500 /etc/wazuh-indexer/certs
chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

echo "Certificates generated successfully"
