#!/usr/bin/env bash

set -v
mysql -u root -e "CREATE DATABASE IF NOT EXISTS stash_datacite_test"
mysql -u root -e "GRANT ALL PRIVILEGES ON stash_datacite_test.* TO 'travis'@'%';";
