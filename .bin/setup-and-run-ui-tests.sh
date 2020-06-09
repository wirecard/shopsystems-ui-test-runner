#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
TIMESTAMP=$(date +%s)
export SHOP_SYSTEM=${SHOP_SYSTEM_NAME%-*}
export DEFAULT_REPO='shopsystems-ui-test-runner'

NGROK_SUBDOMAIN="${RANDOM}${TIMESTAMP}-${SHOP_SYSTEM_NAME}-${SHOP_SYSTEM_VERSION}"
export NGROK_URL="http://${NGROK_SUBDOMAIN}.ngrok.io"

bash ${DEFAULT_REPO}/.bin/start-ngrok.sh SUBDOMAIN="${NGROK_SUBDOMAIN}"

bash ${DEFAULT_REPO}/${SHOP_SYSTEM_NAME}/start-shopsystem.sh NGROK_URL="${NGROK_URL}" \
  SHOP_VERSION="${SHOP_SYSTEM_VERSION}" \
  PHP_VERSION="${PHP_VERSION}" \
  USE_SPECIFIC_EXTENSION_RELEASE="${IS_LATEST_EXTENSION_RELEASE}" \
  SPECIFIC_RELEASED_SHOP_EXTENSION_VERSION="${LATEST_RELEASED_SHOP_EXTENSION_VERSION}"


bash ${DEFAULT_REPO}/.bin/run-ui-tests.sh NGROK_URL="${NGROK_URL}" \
  SHOP_SYSTEM="${SHOP_SYSTEM}" \
  SHOP_VERSION="${SHOP_SYSTEM_VERSION}" \
  GIT_BRANCH="${GIT_BRANCH}" \
  BROWSERSTACK_USER="${BROWSERSTACK_USER}" \
  BROWSERSTACK_ACCESS_KEY="${BROWSERSTACK_ACCESS_KEY}"
