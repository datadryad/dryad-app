# Transitioning CrossRef funders to ROR

## task to add NIH grouping for ROR

```bash
RAILS_ENV=development bundle exec rails affiliation_import:populate_nih_ror_group
```

## task to re-import the latest CrossRef to ROR mapping data

Truncate the table to remove all current entries.  The table is called `stash_engine_xref_funder_to_rors`.
You can download the latest ROR exports at https://doi.org/10.5281/zenodo.6347574 .

```bash
RAILS_ENV=development bundle exec rails affiliation_import:populate_funder_ror_mapping /path/to/file
```

## task to re-import latest ROR data

```bash
# NOPE!  NOT WORKING! RAILS_ENV=development bundle exec rails affiliation_import:update_ror_orgs
RAILS_ENV=development bundle exec rails affiliation_import:populate_ror_db /path/to/file
```