#!/usr/bin/env bash

set -e

BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}
ENGINES_DIR=$(realpath ..)/stash_engines

# ############################################################
# stash_engine

mkdir ${ENGINES_DIR}
cd ${ENGINES_DIR}
echo "Cloning stash_engine into $(pwd)"
git clone https://github.com/CDLUC3/stash_engine.git
cd stash_engine
git checkout ${BRANCH}
echo "Bundling in $(pwd): $(which bundle)"
bundle install

SE_REVISION=$(git rev-parse HEAD)
echo "Checked out stash_engine branch ${BRANCH}, revision ${SE_REVISION}"

# ############################################################
# stash_discovery

cd ${ENGINES_DIR}
echo "Cloning stash_discovery into $(pwd)"
git clone https://github.com/CDLUC3/stash_discovery.git
cd stash_discovery
git checkout ${BRANCH}&& \
  echo "Bundling in $(pwd): $(which bundle)"
bundle install

SD_REVISION=$(git rev-parse HEAD)
echo "Checked out stash_discovery branch ${BRANCH}, revision ${SD_REVISION}"

# ############################################################
# stash_datacite

cd ${ENGINES_DIR}
echo "Cloning stash_datacite into $(pwd)"
git clone https://github.com/CDLUC3/stash_datacite.git
cd stash_datacite
echo "Bundling in $(pwd): $(which bundle)"
git checkout ${BRANCH}
bundle install

SD_REVISION=$(git rev-parse HEAD)
echo "Checked out stash_datacite branch ${BRANCH}, revision ${SD_REVISION}"
