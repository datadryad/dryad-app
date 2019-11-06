#!/usr/bin/env bash

mysql -u root -e "CREATE DATABASE IF NOT EXISTS stash_merritt"
mysql -u root -e "GRANT ALL PRIVILEGES ON stash_merritt.* TO 'travis'@'%';";
set -v
