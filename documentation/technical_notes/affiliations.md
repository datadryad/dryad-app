
Author affiliations
===================

Author affiliations are associated with ROR identifiers. When there is
not corresponding ROR identifier for an affiliation, the affiliation
name is stored with an asterisk appended, so the curators can easily
see that there is no maching ROR.

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

When an affiliation name is not recognized by the system, the title is stored with an
asterisk appended. Ideally, all affiliations will appear in ROR, so we can change them to
controlled names.

Search for affiliations that are candidates to fix, in the database:
```
SELECT long_name, COUNT(long_name)
FROM dcs_affiliations
WHERE long_name like '%*%'
GROUP BY long_name
ORDER BY COUNT(long_name);
```

For each affiliation, determine whether there is a corresponding ROR entry in our
database.

IF there is no corresponding ROR, leave it alone.

IF there is a corresponding ROR, update the associated affiliation entries to have the correct values, using a process like:
```
# find offending identifiers
aa = StashDatacite::Affiliation.where("long_name like '%<INST_NAME>%*'")
aa.each do |a|
  a.authors.each do |auth|
	  puts auth.resource.identifier.identifier if auth.resource_id == auth.resource.identifier.last_submitted_resource&.id
  end
end;nil

# for a given identifier, fix the issue
i = StashEngine::Identifier.where("identifier like '%<IDENT>'").first
r = i.latest_submitted_resource
# find the offending author in r
# replace their affilation with a new one
affil = StashDatacite::Affiliation.where("long_name like '%<INST_NAME>%*'").first
auth.affilation = affil
```
