#!/bin/bash
PREVIEW_LINK='https://raw.githack.com/wirecard/reports'
REPORT_FILE='report.html'

case ${GATEWAY} in
	"NOVA") CHANNEL='shs-ui-nova';;
	"API-WDCEE-TEST") CHANNEL='shs-ui-api-wdcee-test';;
	"API-TEST") CHANNEL='shs-ui-api-test';;
  "TEST-SG") CHANNEL='shs-ui-test-sg';;
  "SECURE-TEST-SG") CHANNEL='shs-ui-secure-test-sg';;
	*) ;;
esac

export SHOP_SYSTEM=${SHOP_SYSTEM_NAME%-*}

curl -X POST -H 'Content-type: application/json' \
    --data "{'text': 'Build Failed. ${SHOP_SYSTEM^} version: ${SHOP_SYSTEM_VERSION}\n
    Build URL : https://github.com/wirecard/${SHOP_SYSTEM_NAME}/actions/runs/${GITHUB_RUN_ID}\n
    Build Number: ${GITHUB_RUN_ID}\n
    Branch: ${GIT_BRANCH}', 'channel': '${CHANNEL}'}" ${SLACK_ROOMS}

PNG_REPORT=$(jq -r ".$SHOP_SYSTEM.png" extension-shop-system-builder/configuration.json)

FAILED_TESTS=$(ls -1q "$PNG_REPORT" | wc -l)

curl -X POST -H 'Content-type: application/json' --data "{
    'attachments': [
        {
            'fallback': 'Failed test data',
            'text': 'There are failed tests.
             Test report: ${PREVIEW_LINK}/${SCREENSHOT_COMMIT_HASH}/${RELATIVE_REPORTS_LOCATION}/${REPORT_FILE} .
             All screenshots can be found  ${REPO_LINK}/tree/${SCREENSHOT_COMMIT_HASH}/${RELATIVE_REPORTS_LOCATION} .',
            'color': '#fc0000'
        }
    ], 'channel': '${CHANNEL}'
}"  ${SLACK_ROOMS};
