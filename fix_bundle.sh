#!/bin/bash
branch=`git rev-parse --abbrev-ref HEAD` ; RAILS_ENV=$branch LOCAL_ENGINES=false bundle update stash_engine stash_datacite stash_discovery
