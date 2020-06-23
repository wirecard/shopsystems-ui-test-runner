#!/bin/bash
# This script will send the notification if 'fail' parameter is passed it will
set -e # Exit with nonzero exit code if anything fails
export REPO_NAME='reports'
export REPO_LINK="https://github.com/wirecard/${REPO_NAME}"
export REPO_ADDRESS="${REPO_LINK}.git"
export GATEWAY='API-TEST'

echo "Timestamp : $(date)"

git clone ${REPO_ADDRESS}
export TODAY=$(date +%Y-%m-%d)

export PROJECT_FOLDER="${SHOP_SYSTEM_NAME}-${SHOP_SYSTEM_VERSION}"
if [ ! -d "${REPO_NAME}/${PROJECT_FOLDER}/${GATEWAY}" ]; then
mkdir -p ${REPO_NAME}/${PROJECT_FOLDER}/${GATEWAY}
fi

if [ ! -d "${REPO_NAME}/${PROJECT_FOLDER}/${GATEWAY}/${TODAY}" ]; then
mkdir ${REPO_NAME}/${PROJECT_FOLDER}/${GATEWAY}/${TODAY}
fi

export BRANCH_FOLDER=${GIT_BRANCH}
export RELATIVE_REPORTS_LOCATION=${PROJECT_FOLDER}/${GATEWAY}/${TODAY}/${BRANCH_FOLDER}

if [ ! -d "${REPO_NAME}/${RELATIVE_REPORTS_LOCATION}" ]; then
    mkdir ${REPO_NAME}/${RELATIVE_REPORTS_LOCATION}
fi

export SHOP_SYSTEM=${SHOP_SYSTEM_NAME%-*}

HTML_REPORT=$(jq -r ".$SHOP_SYSTEM.html" shopsystems-ui-test-runner/configuration.json)
XML_REPORT=$(jq -r ".$SHOP_SYSTEM.xml" shopsystems-ui-test-runner/configuration.json)
PNG_REPORT=$(jq -r ".$SHOP_SYSTEM.png" shopsystems-ui-test-runner/configuration.json)

cp ${HTML_REPORT} ${REPO_NAME}/${RELATIVE_REPORTS_LOCATION}
cp ${XML_REPORT} ${REPO_NAME}/${RELATIVE_REPORTS_LOCATION}
if [[ $1 == 'fail' ]]; then
    cp ${PNG_REPORT} ${REPO_NAME}/${RELATIVE_REPORTS_LOCATION}
fi

cd ${REPO_NAME}

git add ${PROJECT_FOLDER}/${GATEWAY}/${TODAY}/*
git commit -m "Add failed test screenshots from https://github.com/wirecard/${SHOP_SYSTEM_NAME}/actions/runs/${GITHUB_RUN_ID}"
git push -q https://${GITHUB_TOKEN}@github.com/wirecard/${REPO_NAME}.git master

export SCREENSHOT_COMMIT_HASH=$(git rev-parse --verify HEAD)
if [[ $1 == 'fail' ]]; then
    cd ..
    bash shopsystems-ui-test-runner/.bin/send-notify.sh
fi
