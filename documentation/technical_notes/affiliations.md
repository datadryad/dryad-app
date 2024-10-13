
Author affiliations
===================

Author affiliations are associated with ROR identifiers.

Overview of the UI pieces
- on the view for editing a dataset, there is a partial for the given
  affiliation
  - `stash/stash_datacite/app/views/stash_datacite/authors/_affiliation.html.erb`
- this partial makes a GET call to find the affiliation values
  - `https://datadryad.org/stash_datacite/affiliations/autocomplete?term=unc`
- the affiliation_controller handles the GET and makes the actual call
  to ROR to find the values, then returns JSON into the partial for
  rendering
  - `stash/stash_datacite/app/controllers/stash_datacite/affiliations_controller.rb`
  - `stash_engine/lib/stash/organization/ror.rb`

Cleaning affiliation names
==========================

When an affiliation name is not recognized by the system, it is stored without an accompanying ror_id. Ideally, all affiliations will eventually appear in ROR, so we can change them to controlled names.

Search for affiliations that are candidates to fix, in the database:
```ruby
StashDatacite::Affiliation.where(ror_id: nil).select(:long_name).distinct
```

Determine whether there is a corresponding ROR entry in our database.

IF there is a corresponding ROR, update the associated authors to use the correct affiliations and destroy the unmatched ones, using a process like:

```ruby
#see if there is a correct affiliation
rep = StashDatacite::Affiliation.find_by(ror_id: <ror_id>) || StashEngine::Affiliation.from_ror_id(ror_id: <ror_id>)
to_fix = StashDatacite::Affiliation.where(ror_id: nil, long_name: <>)
to_fix.each do |aff|
  if aff.authors.blank?
    aff.destroy
    next
  end
  aff.authors.each do |auth|
    auth.affiliation = rep
  end
  aff.destroy
end
```
