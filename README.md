# Dryad

[![Build Status](https://travis-ci.org/CDLUC3/dashv2.svg?branch=development)](https://travis-ci.org/CDLUC3/dashv2)

## Introduction

**Dryad** is the [UC Curation Center](http://www.cdlib.org/uc3/)'s
implementation of the [Stash](https://github.com/CDL-Dryad/stash) application
framework for research data publication and preservation, based on the
[DataCite Metadata Schema](https://schema.datacite.org/) and the University
of California’s [Merritt](https://merritt.cdlib.org/) repository service.

- [About Dryad](app/views/layouts/_about.html.md)

## Development

More detailed documentation is available in the [documentation folder](https://github.com/CDL-Dryad/dryad-app/blob/main/documentation)

### Installation

See
[Dryad Installation](https://github.com/CDL-Dryad/dryad-app/blob/main/documentation/dryad_install.md)
for installation notes.

### Quick Cheat Sheet

#### Development environment setup

At the same level as the `dashv2` directory:

- Clone the [Stash](https://github.com/CDL-Dryad/stash) repository (public):

  ```
  git clone https://github.com/CDL-Dryad/stash.git
  ```

- Clone the [dryad-config](https://github.com/cdlib/dryad-config/) repository
  (private to CDL developers):

  ```
  git clone git@github.com:cdlib/dryad-config.git
  ```

- Symlink configuration files from `dryad-config` into the `dryad`
  `config` directory:

  ```
  ./symlink_config.sh
  ```

#### Running integration/feature tests locally

In the `dryad` directory:

- run `travis-prep.sh`
- run `bundle exec rspec`

#### Capistrano deployment

To deploy the latest (committed) code from GitHub:

```
bundle exec cap <environment> deploy [BRANCH="<branch-or-tag-name>"]
```

The `$BRANCH` environment variable is optional; if it’s omitted, the
deploy script will prompt you.

#### Miscellaneous tasks

- The `rails app_data:clear` task will clear most database and SOLR data. It
  can be useful to run before testing data import and transformation from our
  previous version of the app. It will not erase data in the production
  environment or until it gets confirmation that you really want to erase the
  data. 

  ```
  bundle exec rails app_data:clear RAILS_ENV=<rails-environment>
  ```

