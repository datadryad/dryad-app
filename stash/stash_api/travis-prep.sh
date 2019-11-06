#!/usr/bin/env bash

set -v
mysql -u root -e "CREATE DATABASE IF NOT EXISTS stash_api_test"
mysql -u root -e "GRANT ALL PRIVILEGES ON stash_api_test.* TO 'travis'@'%';";
