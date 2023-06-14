# Crossref Funder ID to ROR comparison

## Evaluating the mapping of Crossref Funder IDs to ROR IDs

In order to evaluate how well these identifiers map from one to the other, it's easiest to get the identifiers into 
our database so we can join and compare them.

Update the ROR database with the latest dump by running a task like this (warning takes a long
time, like 4 hours to run):
```bash
RAILS_ENV=production bundle exec rails affiliation_import:update_ror_orgs
```

Download the zip and extract the json file from https://doi.org/10.5281/zenodo.6347574:
```bash
RAILS_ENV=<environment> bundle exec rails affiliation_import:populate_funder_ror_mapping <path/to/ror/dump.json>
```

After the imports you can run the following query to see how items in the database map and that
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

To see unmatched identifiers where a ror matching doesn't exist for the fundref ID:

```sql
SELECT DISTINCT c.contributor_name as xref_name, c.name_identifier_id
  FROM dcs_contributors c
  LEFT JOIN stash_engine_xref_funder_to_rors x
    ON c.name_identifier_id = x.xref_id
 WHERE c.identifier_type = 'crossref_funder_id' and c.contributor_type = 'funder'
    AND c.name_identifier_id <> '' AND x.ror_id IS NULL;
```

See the unmatched fundref IDs with a count of number of times they occur.  This is probably the one
to export as CSV or similar for the ROR team to analyze and see if there are funder IDs to add:

```sql
SELECT unmatched.*, c2.num_uses FROM
  (SELECT DISTINCT c.contributor_name as xref_name, c.name_identifier_id
    FROM dcs_contributors c
    LEFT JOIN stash_engine_xref_funder_to_rors x
      ON c.name_identifier_id = x.xref_id
   WHERE c.identifier_type = 'crossref_funder_id' and c.contributor_type = 'funder'
      AND c.name_identifier_id <> '' AND x.ror_id IS NULL) as unmatched
  JOIN
  (SELECT name_identifier_id, count(name_identifier_id) num_uses
     FROM dcs_contributors
     GROUP BY name_identifier_id) as c2
  ON unmatched.name_identifier_id = c2.name_identifier_id
ORDER BY c2.num_uses DESC;
```


Items that are funders but don't match a fundref ID:

```sql
SELECT DISTINCT contributor_name, contributor_type, identifier_type, name_identifier_id
  FROM dcs_contributors
 WHERE contributor_type = 'funder' AND name_identifier_id ='';
```