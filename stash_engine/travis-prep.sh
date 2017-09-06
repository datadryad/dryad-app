#!/usr/bin/env bash

set -v
mysql -u root -e "CREATE DATABASE IF NOT EXISTS stash_engine_test"
mysql -u root -e "GRANT ALL PRIVILEGES ON stash_engine_test.* TO 'travis'@'%';";
