------------------------------------------------------------
# Tasks

## Harvesting

- create demo-only ResourceSync implementation
- create protocol-agnostic abstraction(s) on top of both ResourceSync and OAI-PMH implementations
    - `HarvestTask`
    - `HarvestedRecord`
    - ...?
- create ActiveRecord models sufficient to achieve the following for both protocols
    - schedule a harvest
    - execute a harvest
    - temporarily store harvested records
    - query to determine what the next harvest should be

## Design

- resolve tensions around asynchronous indexing, harvesting/indexing independence

## Indexing

- figure out indexing

## Job Queuing

- figure out what ActiveJobs we need
- figure out ActiveJob configuration

### Active Job

"Active Job is a framework for declaring jobs and making them run on a variety of queueing backends"

- [Active Job basics](http://edgeguides.rubyonrails.org/active_job_basics.html)
- [Active Job integration testing with Rspec](http://briandear.co/2015/01/19/rails-active-job-integration-testing-with-rspec/)

## Configuration

- determine what needs to be configured
- determine config file format & write config-reading code

## Control

- figure out workflow/states (see below under [Workflow / State Transitions](#workflow--state-transitions))

## Error handling

- handle temporary harvesting failures
- handle temporary indexing failures
- handle permanent harvesting failures
- handle permanent indexing failures
- handle configuration errors (may count as permanent whatever failures)
    - e.g., specifying an invalid metadata format

## Optional goodies

- simple wrappers for OAI-PMH `Identify` and `ListMetadataFormats` (for debugging)
- secure UI to:
    - schedule harvests & indexes
    - view log records etc.

------------------------------------------------------------
# Design notes

## Overall process

- stash schedules a harvest task
- we create a harvest-and-index job, which
    - executes the harvest
    - schedules an index job

**Question:** Do we index exactly and only what we harvested? Or do we index whatever needs indexing?    

## Workflow / State Transitions

- ideally harvesting and indexing should be independent
    - but: index-on-harvest? (or after-?)
    - answer: wrap in something that knows about both
- harvest operations should be independent of one another
- index operations should be independent of one another
- work scheduling / invocation should be independent of the actual operations
    - but: index-on-harvest? (or after-?)
    
### Possible workflow for OAI-PMH

Given a `from` datestamp:
- make a `listRecords` call for all records at or after that datestamp
- if the call fails
    - log the failure, but don't change the start datestamp
- if the call succeeds
    - **TODO:** put each record or batch of records in temp storage?
    - for each record
        - add the record to solr
            - if the add operation succeeds
                - log that
            - if the add operation fails
                - if it's a permanent failure
                    - mark that as skippable
                - if it's a temporary failure
                    - log that
    - hard commit
        - if the commit fails
            - log the failure, but don't change the start datestamp
            - mark all records as failed?
        - if the commit succeeds
            - log the success
            - if there are temporary failures
                - record the datestamp of the earliest temporary failure as the next start datestamp
            - otherwise
                - record the datestamp latest success as the next start datestamp

### Possible workflow for ResourceSync

- "Baseline synchronization": either
    - retrieve Resource List for source and retrieve each URL, or
    - retrieve Resource Dump and Resource Dump Manifest for source and retrieve URL content from dump ZIP file
- "Incremental synchronization": either
    - repeat as above, or
    - instead use Change List / Change Dump & Change Dump Manifest (preferred)
        - discover Change List(s) based on published Capability List(s)
        - keep track of the last processed Change List
        - distinguish between 'open' and 'closed' Change Lists (see under [spec section 12.1](http://www.openarchives.org/rs/1.0/resourcesync#ChangeList))

1. Get the (well-known) Capability List for the metadata.
2. For baseline synchronization:
    - if a Resource Dump exists, get that, and
        - if it's a plain dump, get each bitstream package, and
            - extract each resource from the package
        - if it's a Resource Dump Index, flatten to download each bitstream package in each described dump, then extract each resource from each package
    - otherwise, get the Resource List, and
        - if it's a plain list, download each resource
        - if it's a Resource List Index, flatten to download each resource in each described list
3. For incremental synchronization:
    - (same thing but filter changelists based on dates)


## Deployment

Solr setup:

- Where do we assume Solr lives / how do we assume Solr is deployed?
- Do we take Solr as a given, the way we take the repository as a given, or is it (conceptually) embedded our Blacklight app?
- Are we the only source of Solr data?

Solr configuration:

- Compare [DataCite's Solr config](https://github.com/datacite/search/tree/master/src/main/resources)
