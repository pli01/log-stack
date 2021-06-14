#!/bin/bash
#
# quick docker deploy
#
set -e -o pipefail
set -x

# optional dockerhub login
export DOCKERHUB_LOGIN="${DOCKERHUB_LOGIN:-}"
export DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN:-}"

export DOCKER_REGISTRY_USERNAME="${DOCKER_REGISTRY_USERNAME:-}"
export DOCKER_REGISTRY_TOKEN="${DOCKER_REGISTRY_TOKEN:-}"

export APP_NAME="${APP_NAME:-log-stack}"
export APP_BRANCH="${APP_BRANCH:-master}"
export APP_URL="https://github.com/pli01/${APP_NAME}/archive/refs/heads/${APP_BRANCH}.tar.gz"

# if authenticated repo
if [ -n "${GITHUB_TOKEN}" ] ; then
  curl_args=" -H \"Authorization: token ${GITHUB_TOKEN}\" "
fi

# if APP_ROLE defined use make up-${APP_ROLE}
if [ -n "$APP_ROLE" ] ;then
 app_role="-${APP_ROLE}"
fi

# download install repo
mkdir -p ${APP_NAME}
curl -kL -s $curl_args ${APP_URL} | \
   tar -zxvf - --strip-components=1 -C ${APP_NAME}
# install app (role)
( cd ${APP_NAME}
  [ -n "$DOCKERHUB_TOKEN" -a -n "$DOCKERHUB_LOGIN" ] &&  echo $DOCKERHUB_TOKEN | \
      docker login --username $DOCKERHUB_LOGIN --password-stdin

  make registry-login
  make efk-pull
  make efk-down$app_role
  make efk-up$app_role
  make efk-test-up$app_role
  make registry-logout || true

  [ -n "$DOCKERHUB_TOKEN" -a -n "$DOCKERHUB_LOGIN" ] && docker logout
  exit 0
)

