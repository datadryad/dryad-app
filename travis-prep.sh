#!/usr/bin/env bash

# ############################################################
# Setup

PROJECT_ROOT=`pwd`

# ############################################################
# Local dependencies

if [ ! -d ../stash ]; then
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}

  echo "Cloning https://github.com/CDLUC3/stash:"
  cd ..

  set -x
  git clone https://github.com/CDLUC3/stash
  cd stash
  git checkout ${BRANCH}
  { set +x; } 2>/dev/null

  SE_REVISION=$(git rev-parse HEAD)
  echo "Checked out stash branch ${BRANCH}, revision ${SE_REVISION}"

  cd ${PROJECT_ROOT}
fi


# ############################################################
# Test database

echo "Initializing database:"
set -x
mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS dashv2_test'
{ set +x; } 2>/dev/null

# ############################################################
# Configuration

echo "Copying configuration files:"
cd .config-travis
CONFIG_FILES=$(find . -type f | sed "s|^\./||")
cd ${PROJECT_ROOT}
for CONFIG_FILENAME in ${CONFIG_FILES}; do
  SOURCE_FILE=.config-travis/${CONFIG_FILENAME}
  DEST_FILE=config/${CONFIG_FILENAME}
  if [ -f ${DEST_FILE} ]; then
    echo "  skipping existing file ${DEST_FILE}"
  else
    set -x
    cp ${SOURCE_FILE} ${DEST_FILE}
    { set +x; } 2>/dev/null
  fi
done
