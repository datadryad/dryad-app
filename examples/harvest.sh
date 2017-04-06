#!/usr/bin/env bash

export STASH_ENV=development
CONFIG_FILE=`dirname $0`/stash-harvester.yml
STOP_FILE=`dirname $0`/stash-harvester.stop
#bundle install
bundle exec stash-harvester -c ${CONFIG_FILE} -s ${STOP_FILE}

