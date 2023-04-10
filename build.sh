#!/usr/bin/env bash

RBB_VERSION=${RBB_VERSION:-latest}
RBB_IMAGE=${RBB_IMAGE:-rbb:${RBB_VERSION}}

docker build --tag=rbb --network=host .
