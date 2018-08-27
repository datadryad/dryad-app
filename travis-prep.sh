#!/usr/bin/env bash
 
# ############################################################
# Setup

# Make sure we know where we are
PROJECT_ROOT=`pwd`
GITHUB_USER=`git config --get remote.origin.url | sed 's/https:\/\/github\.com\///' | sed 's/\/.*$//'`

# Fail fast
set -e

# ############################################################
# Local dependencies

if [ ! -d ../stash ]; then
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}

  echo "Cloning https://github.com/$GITHUB_USER/stash:"
  cd ..

  set -x
  git clone https://github.com/$GITHUB_USER/stash

  echo "Checking out stash branch ${BRANCH}"

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
mysql -u root -e 'CREATE DATABASE IF NOT EXISTS dashv2_test'
mysql -u root -e 'GRANT ALL ON dashv2_test.* TO travis@localhost'
{ set +x; } 2>/dev/null

# ############################################################
# Configuration

bash symlink_config.sh
