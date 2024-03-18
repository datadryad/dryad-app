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

Warning: This task isn't fast and you may need to give it some time to run.

```bash
RAILS_ENV=development bundle exec rails affiliation_import:update_ror_orgs
```

## Query to back up ROR data to a new table

Delete table if it exists already dcs_contributors_fundref_backup

```sql
CREATE TABLE dcs_contributors_fundref_backup AS SELECT * FROM dcs_contributors;
```

## Query to update CrossRef Funder data to ROR

You can see what identifier ids wouldn't be converted.  There are around ~1100 of these.
```sql
SELECT DISTINCT contrib.name_identifier_id
  FROM dcs_contributors contrib
    LEFT JOIN stash_engine_xref_funder_to_rors xror
    ON contrib.name_identifier_id = xror.xref_id
WHERE contrib.contributor_type - 'funder'
  AND contrib.identifier_type = 'crossref_funder_id'
  AND xror.xref_id IS NULL;
```

To update these IDs to the new ROR values.

If you would like to test this out on a different table, you can use that table name instead of
`dcs_contributors` in the query below.  Perhaps try on a copied table (see above on how to copy table contents)
if you  want to see the results before doing it.  You wouldn't want to do this on your backup table, though, since it 
would transform the data and no longer be a backup after that.

```sql
UPDATE	dcs_contributors contrib
	INNER JOIN stash_engine_xref_funder_to_rors xror
		ON contrib.name_identifier_id = xror.xref_id
SET contrib.contributor_name = xror.org_name,
	contrib.identifier_type = 'ror',
	contrib.name_identifier_id = xror.ror_id
WHERE contrib.contributor_type = 'funder'
	AND contrib.identifier_type = 'crossref_funder_id';
```

## Script to re-populate the SOLR search data (which has funder facets)

Run to update the SOLR information. (Verifited to work with ROR as well as crossref funders)
```bash
RAILS_ENV=development bundle exec rails rsolr:reindex
```

## Resubmit updates to DataCite

Update the DataCite records with updated metadata.

```bash
RAILS_ENV=development bundle exec rails datacite_target:update_dryad
```