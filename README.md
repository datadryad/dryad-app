# Dryad
 
<!-- [![Build Status](https://travis-ci.com/datadryad/dryad-app.svg?branch=main)](https://travis-ci.com/datadryad/dryad-app) -->

## Introduction

**Dryad** is a research data publishing platform based on the [UC Curation Center](http://www.cdlib.org/uc3/)'s
implementation of the [Stash](https://github.com/CDL-Dryad/stash) application framework. It relies on metadata based on the
[DataCite Metadata Schema](https://schema.datacite.org/).

- [About Dryad](https://datadryad.org/)

## Development

More detailed documentation is available in the [documentation folder](https://github.com/datadryad/dryad-app/blob/main/documentation)

### Installation

See
[Dryad Installation](https://github.com/datadryad/dryad-app/blob/main/documentation/dryad_install.md)
for installation notes.

### Quick Cheat Sheet

#### Running integration/feature tests locally

In the `dryad-app` directory:

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
