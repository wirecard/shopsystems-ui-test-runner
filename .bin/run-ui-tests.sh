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
  TEST_SUITE_BRANCH=${TEST_SUITE_BRANCH}
  export EXTENSION_VERSION="${TEST_SUITE_BRANCH}"
else
  TEST_SUITE_BRANCH=master
  export EXTENSION_VERSION="${GIT_BRANCH}"
fi

git clone  --branch "${TEST_SUITE_BRANCH}" https://github.com/wirecard/shopsystems-ui-testsuite.git
cd shopsystems-ui-testsuite

echo "Installing shopsystems-ui-testsuite dependencies"
docker run --rm -i --volume $(pwd):/app prooph/composer:7.2 install --dev

export SHOP_SYSTEM="${SHOP_SYSTEM}"
export SHOP_URL="${NGROK_URL}"
export SHOP_VERSION="${SHOP_VERSION}"
export DB_HOST="${SHOP_DB_SERVER}"
export DB_NAME="${SHOP_DB_NAME}"
export DB_USER="${SHOP_DB_USER}"
export DB_PASSWORD="${SHOP_DB_PASSWORD}"
export BROWSERSTACK_USER="${BROWSERSTACK_USER}"
export BROWSERSTACK_ACCESS_KEY="${BROWSERSTACK_ACCESS_KEY}"

if [ -n "$FEATURE_FILES" ]; then

  for FEATURE_FILE in ${FEATURE_FILES}; do
    for i in {1..30}; do
      if [[ $FEATURE_FILE == *".feature"* ]]; then
        echo "Running tests on specific branch"
        vendor/bin/codecept run acceptance "$FEATURE_FILE" \
          -g "${TEST_GROUP}" -g "${SHOP_SYSTEM}" \
          --env ci --html --xml
      fi
    done
  done
else

  echo "Running tests"
  vendor/bin/codecept run acceptance \
    -g "${TEST_GROUP}" -g "${SHOP_SYSTEM}" \
    --env ci --html --xml
fi
