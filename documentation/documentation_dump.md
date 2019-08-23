# Dryad Technical Introductory Notes/Documentation Dump

## Demo Instance of Dryad

Our demo instance of Dryad is available at [https://dashdemo.ucop.edu](https://dashdemo.ucop.edu) (available 7am-7pm Pacific time) and you may submit and test freely.

## Github Repositories & Similar

* The main application for Dryad is at [https://github.com/CDL-Dryad/dryad](https://github.com/CDL-Dryad/dryad) with minor customizations and configuration for an installation.  The bulk of the code lives in the stash repository.

* The repository at [https://github.com/CDLUC3/stash](https://github.com/CDLUC3/stash) holds most of our code.

    * The stash_engine and stash_datacite engines hold most of the code for the user interface.

    * The stash_api engine is where we've implemented our preliminary API.

    * The stash_discovery engine is a relatively thin wrapper and customization around Geoblacklight.

    * The repository contains some other libraries/gems for things such as sword or harvesting.

* We have a repository at [https://github.com/cdlib/dryad-config](https://github.com/cdlib/dryad-config) which is private.  We can re-derive some example configs from this (since our example is out of date) or give trusted others access to this repo so long as they keep any sensitive information here private.

* The following repositories are used by or related to more minor aspects of the Dryad service under the  CDLUC3 workspace on github:  dash2-harvester, datacite-mapping, resync-client, dash2-migrator

* Travis.ci continuous integration builds for many of the Dryad subcomponents are available at [https://travis-ci.org/CDLUC3](https://travis-ci.org/CDLUC3) .

* We need to come up with contribution guidelines such as [Contribution Guidelines for DMPTool](https://github.com/DMPRoadmap/roadmap/blob/development/CONTRIBUTING.md), more to come soon.  # TODO

## Documentation

* We have an [installation guide](dryad_install.md) for installing the user-interface part of Dryad along with some of the basic depedencies.

* A basic generalized introduction to Dryad's Dash is available at [https://dash.ucop.edu/stash/about](https://dash.ucop.edu/stash/about) .

* API documentation: [https://github.com/CDLUC3/stash/blob/master/stash_api/basic_submission.md](https://github.com/CDLUC3/stash/blob/master/stash_api/basic_submission.md) and [https://datadryad.org/api/v2/docs/](https://dash.ucop.edu/api/v2/docs/)

* A database [Entity-Relationship diagram](other_files/dash_er_2018-06.pdf).  

    * Note most things are related to stash_engine_resources if you have trouble following all the lines.  stash_engine_identifiers has many resources.

    * "dcs" means DataCite Schema

* [Dataset submission flow](submission_flow.md), one of our longest and more complicated flows.  (Login is also somewhat complicated, but people don’t spend a lot of time doing it.)

* The UI Library from the UX team and how to integrate CSS and major UI changes into the Dash application.  [https://github.com/CDL-Dryad/stash/blob/master/stash_engine/ui-library/README.md](https://github.com/CDL-Dryad/stash/blob/master/stash_engine/ui-library/README.md)

* Please see [how to set up and run tests locally](local_testing_setup.md) so you can add tests and run current tests to be sure nothing breaks.

## Merritt

* [Merritt Architecture](https://github.com/CDLUC3/mrt-doc/wiki/Architecture)

* [Merritt’s low-level storage](https://github.com/CDLUC3/mrt-doc/wiki/Storage)

## Development Process

* Development progress is tracked in the [GitHub CDL-Dryad Development Tracker](https://github.com/CDL-Dryad/dryad-product-roadmap/projects)

