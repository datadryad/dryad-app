# `stash_datacite_specs`

[![Build Status](https://travis-ci.org/CDLUC3/stash_datacite_specs.png?branch=master)](https://travis-ci.org/CDLUC3/stash_datacite_specs) 

RSpec tests for [`stash_datacite`](https://github.com/CDLUC3/stash_datacite).
(In a separate project to work around RubyMine / IDEA issue 
[RUBY-18841](https://youtrack.jetbrains.com/issue/RUBY-18841).)

## Database configuration

For compatibility with Travis, you need

1. a local MySQL installation
2. a `travis@localhost` user with no password
3. a `stash_datacite_test` database
4. `travis` to have all privileges on that database

This should look something like:

```
$ mysql -u root
mysql> create user 'travis'@'localhost';
mysql> create database stash_datacite_test character set UTF8mb4 collate utf8mb4_bin;
mysql> use stash_datacite_test;
mysql> grant all on stash_datacite_test.* to 'travis'@'localhost';
```
