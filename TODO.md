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

### Possible indexing workflow

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


