## Organization

Reorganize test directories

## Error handling

- handle temporary harvesting failures
- handle temporary indexing failures
- handle permanent harvesting failures
- handle permanent indexing failures
- handle configuration errors (may count as permanent whatever failures)
    - e.g., specifying an invalid metadata format

## Optional goodies

- simple wrappers for OAI-PMH `Identify` and `ListMetadataFormats` (for debugging)
- command-line data dumps for tables
- secure UI to:
    - schedule harvests & indexes
    - view log records etc.

## Possible indexing workflow

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

## Misc TODOs

### General

- runs on a configurable schedule
- logs each request
- logs each request result
- logs all errors
- does something intelligent with deleted resources
- README documents OAI-PMH support in detail
- README makes it clear we're at least hypothetically protocol-agnostic
- Gemspec makes it clear we're at least hypothetically protocol-agnostic
- Gemspec 's suitable for submitting to Ruby-Gems
- sends appropriate User-Agent and From headers

### Scheduling

- overlaps date ranges
- starts from the datestamp of the last successfully indexed record
- starts at UTC midnight *before* the datestamp of the last successfully indexed record, when harvesting at day granularity

### State tracking

- records the datestamp of the latest successfully indexed record
- in the event of a "partial success", records the datestamp of the earliest failed record
- maintains enough state to keep track of the start/end datestamp itself

### OAI-PMH

- handles badResumptionToken errors
- handles resumptionTokens with expirationDates

### Indexing

- indexes in batches of a configurable size
- logs each request
- logs each request result
- indexes metadata into Solr



