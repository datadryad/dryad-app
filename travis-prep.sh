#!/usr/bin/env bash

# ############################################################
# Local dependencies

if [ ! -d ../stash ]; then
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}
  cd .. && \
    git clone https://github.com/CDLUC3/stash && \
    cd stash && \
    git checkout ${BRANCH}

  SE_REVISION=$(git rev-parse HEAD)
  echo "Checked out stash branch ${BRANCH}, revision ${SE_REVISION}"
fi

# ############################################################
# Test database

mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS dashv2_test';
