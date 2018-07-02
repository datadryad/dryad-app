# Stash::Harvester 

[![Build Status](https://travis-ci.org/CDL-Dryad/stash-harvester.svg?branch=master)](https://travis-ci.org/CDL-Dryad/stash-harvester) 
[![Code Climate](https://codeclimate.com/github/CDL-Dryad/stash-harvester.svg)](https://codeclimate.com/github/CDL-Dryad/stash-harvester) 
[![Inline docs](http://inch-ci.org/github/CDL-Dryad/stash-harvester.svg)](http://inch-ci.org/github/CDL-Dryad/stash-harvester)

Harvests metadata from a digital repository into
[Solr](http://lucene.apache.org/solr/) for indexing.

## OAI-PMH support

The `Stash::Harvester::OAIPMH` module harvests metadata from an [OAI-PMH](http://www.openarchives.org/pmh/) repoistory.

## ResourceSync support

The `Stash::Harvester::Resync` module harvests metadata from a [ResourceSync](http://www.openarchives.org/rs/1.0/resourcesync) source. It makes the following assumptions:

1. Metadata is a first-class resource with its own lifecycle, its own
   published change lists, etc.
2. A [Capability List](http://www.openarchives.org/rs/1.0/resourcesync#CapabilityList)
   exists, at a well-known URI, to advertise the metadata resources and
   their changes.
3. This Capability List advertises a
   [Change List](http://www.openarchives.org/rs/1.0/resourcesync#ChangeList),
   a [Change Dump](http://www.openarchives.org/rs/1.0/resourcesync#ChangeDump),
   or both.
   * As implied (though not explicitly stated) by the ResourceSync spec, if
     both a Change List and a Change Dump exist, all changes in the Change
     List are also in a corresponding Change Dump. That is, wherever both
     exist, it is sufficient to examine only one or the other.
4. The Change List / Change Dump resources advertised in the Capability
   List may be either single lists / dumps or
   [Change List Indices](http://www.openarchives.org/rs/1.0/resourcesync#ChangeListIndex)
   / [Change Dump Indices](http://www.openarchives.org/rs/1.0/resourcesync#ChangeDumpIndex),
   as advertised in the spec.

## Configuration

To provide a specific configuration file, use the `-c` (or `--config`)
option. Otherwise, `stash-harvester` will first look for a
`stash-harvester.yml` file in the current working directory, and if it
doesn't find one, for `.stash-harvester.yml` (note leading `.`) in the
user's home directory.

A sample configuration file:
```yaml
# Metadata configuration
metadata: ???
  schema: ???

# Database configuration
db:
  adapter: sqlite3
  database: ':memory:'
  pool: 5
  timeout: 5000

# Harvesting source configuration
source:
  protocol: OAI              # Stash::Harvester::OAI::OAISourceConfig
  oai_base_url: http://oai.example.org/oai
  metadata_prefix: some_prefix
  set: some_set
  seconds_granularity: true

# Index destination configuration
index:
  adapter: solr
  url: http://solr.example.org/
  proxy: http://foo:bar@proxy.example.com/
  open_timeout: 120          # connection open timeout in seconds
  read_timeout: 120          # read timeout in seconds
  retry_503: 3               # max retries
  retry_after_limit: 20      # retry wait time in seconds
```

**TO DO: figure out metadata config**

