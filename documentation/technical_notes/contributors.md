
Contributors (Funders and facilities)
=====================================

Contributors (`StashDatacite::Contributors`) are used for funders (`contributor_tyoe: 'funder'`) and for research facilities (`contributor_tyoe: 'sponsor'`), and are associated with ROR identifiers in the `name_identifier_id` column.


Cleaning contributor names
==========================

When funder name is not recognized by the system, it is stored without an accompanying `name_identifier_id`. Ideally, all insitutions will eventually appear in ROR, so we can change them to controlled names.

Search for contributors that are candidates to fix, in the database:
```ruby
StashDatacite::Contributor.where(name_identifier_id: [nil, '']).select(:contributor_name).distinct
```

Determine whether there is a corresponding ROR entry in our database.

If there is a corresponding ROR, update the name_identifier_id columns:

```ruby
StashDatacite::Contributor.where(name_identifier_id: [nil, '']).select(:contributor_name).update(identifier_type: 'ror', name_identifier_id: <ror_id>)
```
