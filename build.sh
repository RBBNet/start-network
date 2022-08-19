#!/usr/bin/env bash

__FILE__="$(readlink -f ${BASH_SOURCE[0]})"
__DIR__="${__FILE__%/*}"

VERSION=${VERSION:-$(git describe --always --dirty)}

BUILD_DIR=$(mktemp -d)

rsync -aR \
    ./commands/ \
    ./.env.configs/log.xml \
    ./.env.configs/prometheus-rules-blockchain.yml \
    ./.env.configs/prometheus-rules-rbb.yml \
    ${BUILD_DIR}

grep -v rbb-lab ./docker-compose.yml.hbs > ${BUILD_DIR}/docker-compose.yml.hbs

cat <<EOF > ${BUILD_DIR}/.env
STACK_NAME=rbb-network

IMAGE_BESU=hyperledger/besu:22.7.0
IMAGE_TRAEFIK=traefik:v2.8.1
IMAGE_PROMETHEUS=prom/prometheus:v2.37.0

APP_WEB_PORT=13000
APP_TRAEFIK_PORT=13002

CONFIG_ROOT=./.env.configs
VOLUMES_ROOT=./volumes
EOF

mkdir -p ${BUILD_DIR}/.env.configs/
cat <<EOF > ${BUILD_DIR}/.env.configs/prometheus.yml.hbs
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - 'rules-blockchain.yml'
  - 'rules-rbb.yml'

scrape_configs:
  - job_name: 'prometheus'
    metrics_path: /prometheus/metrics
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']

  - job_name: 'besu-nodes'
    static_configs:
      - targets:
        {{#each nodes}}
          - {{name}}:9545
        {{/each}}
EOF

tar czf rbb-setup-${VERSION}.tgz -C ${BUILD_DIR} .

# rm -rf ${BUILD_DIR}
