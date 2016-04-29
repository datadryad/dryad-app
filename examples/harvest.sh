#!/usr/bin/env bash

export STASH_ENV=development
CONFIG_FILE=`dirname $0`/stash-harvester.yml
#bundle install
bundle exec stash-harvester -c ${CONFIG_FILE}

