#!/usr/bin/env bash

set -v
mysql -u travis -e 'CREATE DATABASE IF NOT EXISTS  stash_datacite_test';
