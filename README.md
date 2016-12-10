# `stash_datacite_specs`

[![Build Status](https://travis-ci.org/CDLUC3/stash_datacite_specs.png?branch=master)](https://travis-ci.org/CDLUC3/stash_datacite_specs) 

RSpec tests for [`stash_datacite`](https://github.com/CDLUC3/stash_datacite).

## Database configuration

For compatibility with Travis, you need

1. a local MySQL installation
2. a `travis@localhost` user with no password
3. a `stash_engine_test` database
4. `travis` to have all privileges on that database

This should look something like:

```
$ mysql -u root
mysql> create user 'travis'@'localhost';
mysql> create database stash_engine_test;
mysql> use stash_engine_test;
mysql> grant all privileges on stash_engine_test to 'travis'@'localhost';
```
