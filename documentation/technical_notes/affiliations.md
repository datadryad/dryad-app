
Author Affiliations
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

