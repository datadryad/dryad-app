# Dash

[![Build Status](https://travis-ci.org/CDLUC3/dashv2.svg?branch=development)](https://travis-ci.org/CDLUC3/dashv2)

## Introduction

**Dash** is the [UC Curation Center](http://www.cdlib.org/uc3/)'s
implementation of the [Stash](https://github.com/CDLUC3/stash) application
framework for research data publication and preservation, based on the
[DataCite Metadata Schema](https://schema.datacite.org/) and the University
of California’s [Merritt](https://merritt.cdlib.org/) repository service.

- [About Dash](app/views/layouts/_about.html.md)

## Development

### Installation

See
[Dash2 Installation](https://github.com/CDLUC3/dashv2/blob/master/documentation/dash2_install.md)
for installation notes.

### Quick Cheat Sheet

#### Development environment setup

At the same level as the `dashv2` directory:

- Clone the [Stash](https://github.com/CDLUC3/stash) repository (public):

  ```
  git clone https://github.com/CDLUC3/stash.git
  ```

- Clone the [dash2-config](https://github.com/cdlib/dash2-config/) repository
  (private to CDL developers):

  ```
  git clone git@github.com:cdlib/dash2-config.git
  ```

- Symlink configuration files from `dash2-config` into the `dashv2`
  `config` directory:

  ```
  ./symlink_config.sh
  ```

#### Running integration/feature tests locally

In the `dashv2` directory:

- run `travis-prep.sh`
- run `bundle exec rake`

#### Capistrano deployment

To deploy the latest (committed) code from GitHub:

```
bundle exec cap <environment> deploy [BRANCH="<branch-or-tag-name>"]
```

The `$BRANCH` environment variable is optional; if it’s omitted, the
deploy script will prompt you.

#### Miscellaneous tasks

- The `rake app_data:clear` task will clear most database and SOLR data. It
  can be useful to run before testing data import and transformation from our
  previous version of the app. It will not erase data in the production
  environment or until it gets confirmation that you really want to erase the
  data. 

  ```
  bundle exec rake app_data:clear RAILS_ENV=<rails-environment>
  ```
