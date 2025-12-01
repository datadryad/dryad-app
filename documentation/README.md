Dryad Documentation
======================


Dryad's basic documentation philosophy includes 4 levels of
visibility:
1. "Very" public documents -- High-level descriptions and information, on the [Main Dryad website](https://datadryad.org)
2. Public documentation -- Technical documents and other details about dryad. Stored in Github, usually within [this directory](https://github.com/datadryad/dryad-app/tree/main/documentation)
3. Private documentation -- Internal details, for Dryad staff. Stored in Confluence.
4. Private working documents -- Documents that are edited frequently. Stored in Dryad's Google Dive.


# Dryad Technical Introductory Notes  

## Demo Instance of Dryad

Our demo instance of Dryad is available at [https://sandbox.datadryad.org](https://sandbox.datadryad.org) and you may submit and test freely.

## Github Repositories & Similar

* The main application for Dryad is at [https://github.com/datadryad/dryad-app](https://github.com/datadryad/dryad-app) with minor customizations and configuration for an installation. 

    * The stash_engine and stash_datacite modules hold most of the code for the user interface.

    * The stash_api module is where we've implemented our API.

    * The stash_discovery module is a relatively thin wrapper and customization around SOLR.

## Documentation

* We have an [installation guide](dryad_install.md) for installing the user-interface part of Dryad along with some of the basic depedencies.

* A basic generalized introduction to Dryad's architecture is
  available at https://datadryad.org/our_platform .

* [API documentation and specification](https://datadryad.org/api) and [API READMEs](apis)

* A (somewhat dated) database [Entity-Relationship diagram](other_files/dash_er_2018-06.pdf).

    * Note most things are related to stash_engine_resources if you have trouble following all the lines. stash_engine_identifiers has many resources.

    * "dcs" means DataCite Schema

* [Dataset submission flow](submission_flow.md), one of our longest and more complicated flows. (Login is also somewhat complicated, but people don’t spend a lot of time doing it.)

* Please see [how to set up and run tests locally](local_testing_setup.md) so you can add tests and run current tests to be sure nothing breaks.

## Development Process

* Development progress is tracked in the [GitHub CDL-Dryad Development Tracker](https://github.com/datadryad/dryad-product-roadmap/projects)

