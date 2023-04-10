#!/usr/bin/env bash

RBB_VERSION=${RBB_VERSION:-latest}
RBB_IMAGE=${RBB_IMAGE:-rbb:${RBB_VERSION}}

docker build --build-arg http_proxy --build-arg https_proxy --build-arg no_proxy --tag=rbb --network=host .
