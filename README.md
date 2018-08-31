# stash

[![Build Status](https://travis-ci.org/CDL-Dryad/stash.svg?branch=master)](https://travis-ci.org/CDL-Dryad/stash) 

## Introduction

**Stash** is an application framework for research data publication and
preservation. Stash enables individual scholars to:

1. Prepare datasets for curation by reviewing best practice guidance for
   the creation or acquisition of research data.
2. Select data for curation through local file browse or drag-and-drop
   operation.
3. Describe data in terms of scientifically-meaning metadata.
4. Identify datasets for persistent citation, reference, and retrieval.
5. Preserve, manage, and share data in an appropriate data repository.
6. Discover, retrieve, and reuse data through faceted search and browse.

By alleviating many of the barriers that have historically precluded wider
adoption of open data principles, Stash empowers individual scholars to
assert active curation control over their research outputs; encourages more
widespread data preservation, publication, sharing, and reuse;
and promotes open scholarly inquiry and advancement.

[Dash](https://dash.ucop.edu/) is the
[UC Curation Center](http://www.cdlib.org/uc3/)'s implementation of Stash.
For the Dash source code, see the [dashv2](https://github.com/CDLUC3/dashv2)
repository.

The next generation of [Dryad](https://datadryad.org) is being rebuilt
with the Stash core. For the Dryad source code, see the
[dryad](https://github.com/CDL-Dryad/dryad) repository.

## Architecture

Stash is intended to be applicable to any standards-compliant repository
that supports the
[SWORD 2](https://swordapp.github.io/SWORDv2-Profile/SWORDProfile.html)
protocol for deposit and [OAI-PMH](https://www.openarchives.org/pmh/) or
[ResourceSync](http://www.openarchives.org/rs/1.1/resourcesync) protocols
for metadata harvesting.

![Stash architecture](https://raw.githubusercontent.com/CDLUC3/dash/gh-pages/docs/stash_architecture.png)

## Contributing

For individual projects, `bundle exec rake` will run unit tests, check test
coverage, and check code style. Use `bundle exec rubocop -a` to identify
code style problems and auto-fix any that can be auto-fixed. In general,
all projects follow the top-level [`rubocop.yml`](rubocop.yml) code style
configuration, with judicious exceptions.

Run [`travis-build.rb`](travis-build.rb) in the top-level `stash` directory
to bundle, test, and style-check all projects.

