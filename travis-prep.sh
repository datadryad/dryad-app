#!/usr/bin/env bash

# ############################################################
# Setup

PROJECT_ROOT=`pwd`

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

  cd ${PROJECT_ROOT}
fi


# ############################################################
# Test database

echo "mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS dashv2_test'"
mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS dashv2_test'

# ############################################################
# Configuration

echo 'cp config/tenants/tenant.yml.example config/tenants/exemplia.yml'
cp config/tenants/tenant.yml.example config/tenants/exemplia.yml

if [ ! -f config/database.yml ]; then
  echo 'cp config/database.yml.example config/database.yml'
  cp config/database.yml.example config/database.yml
else
  echo 'config/database.yml already exists; ignoring config/database.yml.example'
fi

if [ ! -f config/licenses.yml ]; then
  echo 'cp config/licenses.yml.example config/licenses.yml'
  cp config/licenses.yml.example config/licenses.yml
else
  echo 'config/licenses.yml already exists; ignoring config/licenses.yml.example'
fi
