#/usr/bin/env bash
set -euo pipefail

if [ -z "${QUAY_API_TOKEN}" ]; then
  echo "Error: QUAY_API_TOKEN is not set"
  exit 1
fi

QUAY_REPO="app-sre/er-base-cdktf"
TAG=$( cat VERSION )

function image_tags_count() {
    TAGS=$(curl -s  -H "Authorization: Bearer ${QUAY_API_TOKEN}" \
    https://quay.io/api/v1/repository/${QUAY_REPO}/tag/\?specificTag=${TAG}\&onlyActiveTags=true)
    NUM_TAGS=$(echo $TAGS | jq '.tags | length')
    echo $NUM_TAGS
}

if [ $(image_tags_count) -ne 0 ]; then
    echo "Image ${QUAY_REPO}:${TAG} already exists. Bump the VERSION file to push a new image"
    exit 1
fi

echo "Bulding and Pushing a new image!"
make deploy
