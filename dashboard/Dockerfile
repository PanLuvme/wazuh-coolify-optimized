FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_OPTIONS="--max-old-space-size=768"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends wazuh-dashboard \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "opensearch.ssl.verificationMode: certificate" >> /etc/wazuh-dashboard/opensearch_dashboards.yml && \
    echo "server.host: 0.0.0.0" >> /etc/wazuh-dashboard/opensearch_dashboards.yml

RUN mkdir -p /var/lib/wazuh-dashboard /run/wazuh-dashboard && \
    chown -R wazuh-dashboard:wazuh-dashboard /usr/share/wazuh-dashboard /etc/wazuh-dashboard /var/lib/wazuh-dashboard /run/wazuh-dashboard

USER wazuh-dashboard
WORKDIR /usr/share/wazuh-dashboard

EXPOSE 5601

CMD ["/usr/share/wazuh-dashboard/bin/opensearch-dashboards", "-c", "/etc/wazuh-dashboard/opensearch_dashboards.yml"]
