# Transitioning CrossRef funders to ROR

## task to add NIH grouping for ROR

```bash
RAILS_ENV=production bundle exec rails affiliation_import:populate_nih_ror_group
```

## task to re-import the latest CrossRef to ROR mapping data

Truncate the table to remove all current entries.  The table is called `stash_engine_xref_funder_to_rors`

```bash
RAILS_ENV=production bundle exec rails affiliation_import:populate_funder_ror_mapping /path/to/file
```

## task to re-import latest ROR data

```bash
RAILS_ENV=production bundle exec rails affiliation_import:update_ror_orgs  
```