#!/bin/bash
# build.sh — LOCAL BUILD HELPER (not used in CI/GitHub Actions workflow)
#
# This script uses the homeassistant/amd64-builder Docker image to build
# addon images locally, mirroring what was previously done in Travis CI.
# The GitHub Actions workflow (.github/workflows/build-vzlogger2mqtt.yml)
# is used for all automated builds and Docker Hub releases.
#
# Usage (from repo root):
#   ./build.sh vzlogger2mqtt         # build all arches
#   ARCHS="--amd64" ./build.sh vzlogger2mqtt   # build amd64 only (faster)
#   TEST="--test" ./build.sh vzlogger2mqtt      # dry-run without pushing
#
# Prerequisites: Docker must be running and you must be logged in to Docker Hub.
#   docker login -u <your-username>
set -ev
echo "Addons: $@"
archs="${ARCHS}"
for addon in "$@"; do
  if [ -z ${TRAVIS_COMMIT_RANGE} ] || git diff --name-only ${TRAVIS_COMMIT_RANGE} | grep -v README.md | grep -q ${addon}; then
    if [ -z "$archs" ]; then
      archs=$(jq -r '.arch // ["armv7", "armhf", "amd64", "aarch64", "i386"] | [.[] | "--" + .] | join(" ")' ${addon}/config.json)
    fi
    echo "Archs: $archs"
    echo "Test: $TEST"
    docker run \
      --rm \
      --privileged \
      -v /var/run/docker.sock:/var/run/docker.sock:ro \
      -v ~/.docker:/root/.docker \
      -v $(pwd)/${addon}:/data \
      homeassistant/amd64-builder \
      ${archs} \
      -t /data \
      --no-cache \
      ${TEST}
  else
    echo "No change in commit range ${TRAVIS_COMMIT_RANGE}"
  fi
done



