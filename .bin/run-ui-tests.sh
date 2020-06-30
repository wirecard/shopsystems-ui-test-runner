#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

set -a
source ${DEFAULT_REPO}/${SHOP_SYSTEM_NAME}/.env
set +a

export ENV_FILE=${DEFAULT_REPO}/${SHOP_SYSTEM_NAME}/.env
export DOCKER_COMPOSE_FILE=${DEFAULT_REPO}/${SHOP_SYSTEM_NAME}/docker-compose.yml

for ARGUMENT in "$@"; do
  KEY=$(echo "${ARGUMENT}" | cut -f1 -d=)
  VALUE=$(echo "${ARGUMENT}" | cut -f2 -d=)

  case "${KEY}" in
  NGROK_URL) NGROK_URL=${VALUE} ;;
  SHOP_SYSTEM) SHOP_SYSTEM=${VALUE} ;;
  SHOP_VERSION) SHOP_VERSION=${VALUE} ;;
  FEATURE_FILES) FEATURE_FILES=${VALUE};;
  TEST_SUITE_BRANCH) TEST_SUITE_BRANCH=${VALUE};;
  TEST_GROUP) TEST_GROUP=${VALUE};;
  NUMBER_OF_TEST_GROUPS) NUMBER_OF_TEST_GROUPS=${NUMBER_OF_TEST_GROUPS};;
  BROWSERSTACK_USER) BROWSERSTACK_USER=${VALUE} ;;
  BROWSERSTACK_ACCESS_KEY) BROWSERSTACK_ACCESS_KEY=${VALUE} ;;
  *) ;;
  esac
done

if [ -n "$FEATURE_FILES" ]; then
  composer require wirecard/shopsystem-ui-testsuite:dev-"${TEST_SUITE_BRANCH}"

  for FEATURE_FILE in ${FEATURE_FILES}; do
    for i in {1..30}; do
      if [[ $FEATURE_FILE == *".feature"* ]]; then
        docker-compose --env-file "${ENV_FILE}" -f "${DOCKER_COMPOSE_FILE}" run \
	  -e SHOP_SYSTEM="${SHOP_SYSTEM}" \
	  -e SHOP_URL="${NGROK_URL}" \
	  -e SHOP_VERSION="${SHOP_VERSION}" \
	  -e EXTENSION_VERSION="${XTEST_SUITE_BRANCH}" \
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
  echo "installing test suite ${TEST_SUITE_BRANCH}"
  composer require wirecard/shopsystem-ui-testsuite:dev-${TEST_SUITE_BRANCH}

  TEST_GROUP_PREFIX=${TEST_GROUP%_*}
  TEST_NUMBER=${TEST_GROUP#*group_}
  EXCLUDE_TEST_GROUP_FLAG=""

  for (( i=1; i<=$NUMBER_OF_TEST_GROUPS; i++))
  do
    if [ $i != "$TEST_NUMBER" ]; then
      EXCLUDE_TEST_GROUP_FLAG="-x ${TEST_GROUP_PREFIX}_${i} ${EXCLUDE_TEST_GROUP_FLAG}"
    fi
  done


  echo "Running codecept run acceptance -g ${SHOP_SYSTEM} -g ${TEST_GROUP} ${EXCLUDE_TEST_GROUP_FLAG}"

    docker-compose --env-file "${ENV_FILE}" -f "${DOCKER_COMPOSE_FILE}" run \
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
    codecept --version

  docker-compose --env-file "${ENV_FILE}" -f "${DOCKER_COMPOSE_FILE}" run \
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
    -g "${SHOP_SYSTEM}" -g "${TEST_GROUP}" "${EXCLUDE_TEST_GROUP_FLAG}" \
    --env ci --html --xml
fi

#     -g "${SHOP_SYSTEM}" -g "${TEST_GROUP}" "${EXCLUDE_TEST_GROUP_FLAG}" \
