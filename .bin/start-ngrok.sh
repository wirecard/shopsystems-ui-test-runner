#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

for ARGUMENT in "$@"; do
  KEY=$(echo "${ARGUMENT}" | cut -f1 -d=)
  VALUE=$(echo "${ARGUMENT}" | cut -f2 -d=)

  case "${KEY}" in
  SUBDOMAIN) SUBDOMAIN=${VALUE} ;;
  *) ;;
  esac
done

NGROK_ARCHIVE_LINK="https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip"
JQ_LINK="http://stedolan.github.io/jq/download/linux64/jq"

curl -s "${NGROK_ARCHIVE_LINK}" > ngrok.zip
unzip ngrok.zip
chmod +x "${PWD}"/ngrok

curl -sO ${JQ_LINK}
chmod +x "${PWD}"/jq

"${PWD}"/ngrok authtoken "${NGROK_TOKEN}"
"${PWD}"/ngrok http 80 -subdomain="${SUBDOMAIN}" >/dev/null &
NGROK_URL=$(curl -s localhost:4040/api/tunnels/command_line | jq --raw-output .public_url)

while [ ! "${NGROK_URL}" ] || [ "${NGROK_URL}" = 'null' ]; do
  echo "Waiting for ngrok to initialize"
  export NGROK_URL=$(curl -s localhost:4040/api/tunnels/command_line | jq --raw-output .public_url)
  ((c++)) && ((c == 50)) && break
  sleep 1
done
