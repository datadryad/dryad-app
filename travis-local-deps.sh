#!/usr/bin/env bash

BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}
ENGINES_DIR=$(realpath ..)/stash_engines

mkdir ${ENGINES_DIR} && \
  cd ${ENGINES_DIR} && \
  echo "Cloning stash_engine into $(pwd)" && \
  git clone https://github.com/CDLUC3/stash_engine.git && \
  cd stash_engine && \
  git checkout ${BRANCH} && \
  bundle install

SE_REVISION=$(git rev-parse HEAD)
echo "Checked out stash_engine branch ${BRANCH}, revision ${SE_REVISION}"

cd ${ENGINES_DIR} && \
  echo "Cloning stash_discovery into $(pwd)" && \
  git clone https://github.com/CDLUC3/stash_discovery.git && \
  cd stash_discovery && \
  git checkout ${BRANCH}&& \
  bundle install

SD_REVISION=$(git rev-parse HEAD)
echo "Checked out stash_discovery branch ${BRANCH}, revision ${SD_REVISION}"

cd ${ENGINES_DIR} && \
  echo "Cloning stash_datacite into $(pwd)" && \
  git clone https://github.com/CDLUC3/stash_datacite.git && \
  cd stash_datacite && \
  git checkout ${BRANCH}&& \
  bundle install

SD_REVISION=$(git rev-parse HEAD)
echo "Checked out stash_datacite branch ${BRANCH}, revision ${SD_REVISION}"
