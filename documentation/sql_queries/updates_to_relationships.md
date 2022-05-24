# May 2022, updates to relationships for certain work types

This is some documentation and sql queries to change what work types use which relationships as of May 2022
with corrections at DataCite.

The changes are the following:

- Article changed from `cites` to `iscitedby`
- Dataset changed from `issupplementto` to `issupplementedby`
- Preprint changed from `cites` to `iscitedby`
- Software stayed the same as `isderivedfrom`
- Supplemental Information changed from `ispartof` to `issourceof`
- Primary Article changed from `cites` to `iscitedby`
- Data Management Plan stayed the same `isdocumentedby`

You can read these relationships as "Our dataset `is<SomethingedBy>` the `<externalItemType>`".

The rails database enum is the following (the info is needed for direct SQL updates):

```ruby
{ undefined: 0,
  article: 1,
  dataset: 2,
  preprint: 3,
  software: 4,
  supplemental_information: 5,
  primary_article: 6,
  data_management_plan: 7 }
```

Our database can be corrected with these three queries.

```sql
/* update the relationship for articles, preprints and primary articles */
UPDATE dcs_related_identifiers
SET relation_type = 'iscitedby'
WHERE work_type IN (1, 3, 6);
```

```sql
/* update the relation for other datasets */
UPDATE dcs_related_identifiers
SET relation_type = 'issupplementedby'
WHERE work_type = 2;
```

```sql
/* update the relation for supplemental information */
UPDATE dcs_related_identifiers
SET relation_type = 'issourceof'
WHERE work_type = 5;
```
