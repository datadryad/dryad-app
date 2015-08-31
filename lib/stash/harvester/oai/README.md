## OAI-PMH

### Configuration

A YAML configuration file must be provided containing:

- `oai_base_url`: the OAI base URL (required)
- `metadata_prefix`: the metadata prefix (optional; defaults to `oai_dc`)
- `set`: the OAI record set (optional)
- `seconds_granularity` (`true`/`false`): whether the OAI data source uses seconds granularity for timestamps (optional; defaults to `false`)

### Workflow

1. For baseline synchronization:
    - [List](http://www.openarchives.org/OAI/2.0/openarchivesprotocol.htm#ListRecords) all records (optionally: in the configured set) since the beginning of time.
2. For incremental synchronization:
    - given a start and end timestamp range:
        - [List](http://www.openarchives.org/OAI/2.0/openarchivesprotocol.htm#ListRecords) records (optionally: in the configured set) records within that range.
