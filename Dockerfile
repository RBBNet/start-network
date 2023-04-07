ARG BESU_VERSION=latest
ARG BESU_IMAGE=hyperledger/besu:${BESU_VERSION}

ARG NODE_VERSION=latest
ARG NODE_IMAGE=node:${NODE_VERSION}

## build hbs
FROM $NODE_IMAGE AS hbs

WORKDIR /app
RUN npm install hbs-cli

USER 1000:1000
COPY docker/hbs /app/hbs

ENTRYPOINT [ "/app/hbs" ]

## build rbb-cli
FROM $BESU_IMAGE

USER root

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get update \
    && apt-get install -y jq

USER besu

ENV PATH="/opt/rbb/:${PATH}"

COPY --from=hbs /usr/local/bin/node /usr/bin/
COPY --from=hbs /app/ /opt/rbb/

COPY docker/besu-logging-off.xml /var/lib/besu/logging-off.xml
COPY commands/ /opt/rbb/

ENTRYPOINT [ "/opt/rbb/rbb" ]
