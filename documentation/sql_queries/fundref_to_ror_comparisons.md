# Crossref Funder ID to ROR comparison

## Evaluating the mapping of Crossref Funder IDs to ROR IDs

In order to evaluate how well these identifiers map from one to the other, it's easiest to get the identifiers into 
our database so we can join and compare them.

Run a rake task like this example which will put a mapping in stash_engine_xref_funder_to_rors:
```bash
RAILS_ENV=<environment> bundle exec rails affiliation_import:populate_funder_ror_mapping <path/to/ror/dump.json>
```

After the import you can run the following query to see how items in the database map and that
names seem sane where a mapping exists.

```sql
SELECT DISTINCT c.contributor_name as xref_name, x.`xref_id`, x.ror_id, r.name as ror_name
  FROM dcs_contributors c
  JOIN `stash_engine_xref_funder_to_rors` x
    ON c.name_identifier_id = x.`xref_id`
  JOIN stash_engine_ror_orgs r
    ON x.ror_id = r.ror_id
 WHERE c.identifier_type = 'crossref_funder_id' and c.contributor_type = 'funder';
```

To see unmatched identifiers where a ror matching doesn't exist from the identifiers:

```sql
SELECT DISTINCT c.contributor_name as xref_name, c.name_identifier_id
  FROM dcs_contributors c
  LEFT JOIN stash_engine_xref_funder_to_rors x
    ON c.name_identifier_id = x.xref_id
 WHERE c.identifier_type = 'crossref_funder_id' and c.contributor_type = 'funder'
    AND c.name_identifier_id <> '' AND x.ror_id IS NULL;
```