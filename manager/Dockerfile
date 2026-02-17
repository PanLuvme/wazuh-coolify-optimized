FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    procps \
    python3 \
    python3-requests \
    python3-urllib3 \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends wazuh-manager \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY shipper.py /usr/local/bin/shipper.py

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/shipper.py

EXPOSE 1514 1515 55000
VOLUME ["/var/ossec/data", "/var/ossec/logs", "/var/ossec/etc"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
