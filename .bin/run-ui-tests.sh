#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

set -a
source ${DEFAULT_REPO}/${SHOP_SYSTEM_NAME}/.env
set +a

for ARGUMENT in "$@"; do
  KEY=$(echo "${ARGUMENT}" | cut -f1 -d=)
  VALUE=$(echo "${ARGUMENT}" | cut -f2 -d=)

  case "${KEY}" in
  NGROK_URL) NGROK_URL=${VALUE} ;;
  GIT_BRANCH) GIT_BRANCH=${VALUE} ;;
  SHOP_SYSTEM) SHOP_SYSTEM=${VALUE} ;;
  SHOP_VERSION) SHOP_VERSION=${VALUE} ;;
  FEATURE_FILES) FEATURE_FILES=${VALUE};;
  TEST_SUITE_BRANCH) TEST_SUITE_BRANCH=${VALUE};;
  BROWSERSTACK_USER) BROWSERSTACK_USER=${VALUE} ;;
  BROWSERSTACK_ACCESS_KEY) BROWSERSTACK_ACCESS_KEY=${VALUE} ;;
  *) ;;
  esac
done

case ${GIT_BRANCH} in
	${PATCH_RELEASE}) TEST_GROUP="${PATCH_RELEASE}";;
	${MINOR_RELEASE}) TEST_GROUP="${MINOR_RELEASE}";;
	*) TEST_GROUP="${MAJOR_RELEASE}" ;;
esac

if [ -n "$FEATURE_FILES" ]; then
  composer require wirecard/shopsystem-ui-testsuite:dev-"${TEST_SUITE_BRANCH}"

  for FEATURE_FILE in ${FEATURE_FILES}; do
    for i in {1..30}; do
      if [[ $FEATURE_FILE == *".feature"* ]]; then
        docker run \
	  -e SHOP_SYSTEM="${SHOP_SYSTEM}" \
	  -e SHOP_URL="${NGROK_URL}" \
	  -e SHOP_VERSION="${SHOP_VERSION}" \
	  -e EXTENSION_VERSION="${TEST_SUITE_BRANCH}" \
	  -e DB_HOST="${SHOP_DB_SERVER}" \
	  -e DB_NAME="${SHOP_DB_NAME}" \
	  -e DB_USER="${SHOP_DB_USER}" \
	  -e DB_PASSWORD="${SHOP_DB_PASSWORD}" \
	  -e BROWSERSTACK_USER="${BROWSERSTACK_USER}" \
	  -e BROWSERSTACK_ACCESS_KEY="${BROWSERSTACK_ACCESS_KEY}" \
	  codecept run acceptance "$FEATURE_FILE" \
	  -g "${TEST_GROUP}" -g "${SHOP_SYSTEM}" \
	  --env ci --html --xml
      fi
    done
  done
else
  composer require wirecard/shopsystem-ui-testsuite:dev-master

  docker run \
    -e SHOP_SYSTEM="${SHOP_SYSTEM}" \
    -e SHOP_URL="${NGROK_URL}" \
    -e SHOP_VERSION="${SHOP_VERSION}" \
    -e EXTENSION_VERSION="${GIT_BRANCH}" \
    -e DB_HOST="${SHOP_DB_SERVER}" \
    -e DB_NAME="${SHOP_DB_NAME}" \
    -e DB_USER="${SHOP_DB_USER}" \
    -e DB_PASSWORD="${SHOP_DB_PASSWORD}" \
    -e BROWSERSTACK_USER="${BROWSERSTACK_USER}" \
    -e BROWSERSTACK_ACCESS_KEY="${BROWSERSTACK_ACCESS_KEY}" \
    codecept run acceptance \
    -g "${TEST_GROUP}" -g "${SHOP_SYSTEM}" \
    --env ci --html --xml
fi
