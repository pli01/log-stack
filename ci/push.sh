#!/bin/bash
set -e -o pipefail
#set -x

export DOCKER_REGISTRY_USERNAME=${DOCKER_REGISTRY_USERNAME:? DOCKER_REGISTRY_USERNAME not defined}
export DOCKER_REGISTRY_TOKEN=${DOCKER_REGISTRY_TOKEN:? DOCKER_REGISTRY_TOKEN not defined}

make efk-push-image registry-logout

