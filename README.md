# stash

### Introduction

**Stash** is a **UC3** service for storing and sharing research data.  Stash, a replacement for UC3’s current Dash service (UC3, 2015), is simple self-service repository overlay layer for submission and discovery of research datasets.  Stash is intended to be applicable to any standards-compliant repository that supports the SWORD protocol for deposit and the OAI-PMH protocol for metadata harvesting.  Stash enables individual scholars to:

1. Prepare datasets for curation by reviewing best practice guidance for the creation or acquisition of research data.
2. Select data for curation through local file browse or drag-and-drop operation.
3. Describe data in terms of scientifically-meaning metadata.
4. Identify datasets for persistent citation, reference, and retrieval.
5. Preserve, manage, and share data in an appropriate data repository.
6. Discover, retrieve, and reuse data through faceted search and browse.

By alleviating many of the barriers that have historically precluded wider adoption of open data principles, Stash empowers individual scholars to assert active curation control over their research outputs; encourages more widespread data preservation, publication, sharing, and reuse; and promotes open scholarly inquiry and advancement.

### Stash Architecture
<img src="https://raw.githubusercontent.com/CDLUC3/dash/gh-pages/docs/stash_architecture.png" width="720" alt="Architecture">


#This is a work in progress.



* Ruby version ruby 2.2.0p0
* Rails version Rails 4.2.0
* RSpec-Rails testing framework.

### Useful Links

#### [Travis continuous integration](https://travis-ci.org/CDLUC3/dashv2)

---------------------------------------------------------

### Deployment, Operations and Utility Tasks (work in progress)

When using Rails with Capistrano, it is typical to have some deploy tasks as part of the application. These tasks
address our deployment and operational needs such as using Phusion Passenger Standalone (with Apache in front) and
some of our development needs. They may be less useful to others with different set ups.

#### Quick Cheat Sheet

* Deploying with Capistrano (leave off branch and you'll be prompted)
```ruby
cap <capistrano-deploy-environment> deploy BRANCH="<branch-or-tag-name>"
```

* Symlink in tenant and other config files by checking out repo of configuration at same directory level as the this app
directory and then run `./symlink_config.sh`.

* To do development across engines concurrently with this app, create a directory called stash_engines at the same level
as the app and clone the engines inside that directory (stash_datacite, stash_discovery, stash_engine).  They
will be included as local engines by the Gemfile which is our current default for development.

* The rake app_data:clear task will clear most database and SOLR data.  It can be useful to run before testing data
import and transformation from our previous version of the app.  It will not erase data in the production environment
or until it gets confirmation that you really want to erase the data.
```ruby
bundle exec rake app_data:clear RAILS_ENV=<rails-environment>
```