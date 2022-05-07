ARG ALPINE_VERSION=3.15
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
  curl \
  jq

ENV INTERVAL 60
ENV ADGUARD_USERNAME ""
ENV ADGUARD_PASSWORD ""
ENV ADGUARD_DOMAIN ""
ENV TRAEFIK_CERT_JSON ""
ENV ADGUARD_API_SCHEME ""
ENV ADGUARD_API_PORT ""

WORKDIR /agh-updater
COPY agh-updater.sh .
RUN chmod +x agh-updater.sh

ENTRYPOINT ash -C /agh-updater/agh-updater.sh -i ${INTERVAL}
