#!/usr/bin/env bash

# ############################################################
# Setup

PROJECT_ROOT=`pwd`

# ############################################################
# Local dependencies

if [ ! -d ../stash ]; then
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}

  echo "Cloning https://github.com/CDLUC3/stash"
  cd .. && \
    git clone https://github.com/CDLUC3/stash && \
    cd stash && \
    git checkout ${BRANCH}

  SE_REVISION=$(git rev-parse HEAD)
  echo "  Checked out stash branch ${BRANCH}, revision ${SE_REVISION}"
  echo ""

  cd ${PROJECT_ROOT}
fi


# ############################################################
# Test database

echo "Initializing database:"
echo "  mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS dashv2_test'"
mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS dashv2_test'
echo ""

# ############################################################
# Configuration

echo "Copying configuration files:"
cd .config-travis
for f in `find . -type f | sed "s|^\./||"`; do
  if [ -f ${PROJECT_ROOT}/config/${f} ]; then
    echo "  config/${f} already exists; ignoring .config-travis/${f}"
  else
    echo "  cp .config-travis/${f} config/${f}"
    cp .config-travis/${f} ${PROJECT_ROOT}/config/${f}
  fi
done
cd ${PROJECT_ROOT}
echo ""
