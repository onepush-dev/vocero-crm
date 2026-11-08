# Railway packaging of the official Vocero CRM 2.7.0 image (unmodified app).
# Adds a start wrapper that creates the owner account (and with it the
# organization, which closes public sign-up) on a private loopback port before
# the public port opens, so nobody else can claim the instance.
FROM ghcr.io/kevinrivm/vocero-crm:2.7.0@sha256:e77c8fc130e1b07927ad808dd5caca56d35232dfef4fda3c82e84f4b026e6f42
USER root
COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN sed -i 's/\r$//' /usr/local/bin/railway-start.sh && chmod 0755 /usr/local/bin/railway-start.sh
ENV PORT=8080 \
    META_GRAPH_API_VERSION=v25.0 \
    VOCERO_ADMIN_EMAIL=admin@example.com \
    VOCERO_ADMIN_NAME=Admin
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD []
