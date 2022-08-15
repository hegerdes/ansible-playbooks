#!/bin/bash

PAYLOAD_INFO=$(echo $1 | jq)
echo $PAYLOAD_INFO


echo "Payload: ${HOOK_PAYLOAD}"
curl --location --request POST 'XXX' \
    --header 'Content-Type: application/json' \
    --data-raw "${HOOK_PAYLOAD}"
