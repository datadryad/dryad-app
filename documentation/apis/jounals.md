
Dryad Journal Module
======================

The journal module provides information about the journals associated
with Dryad. It runs from the old (v1) Dryad server, so its API is
separate from the newer [data-access API](https://datadryad.org/api/v2/docs/).

List all journals:
`https://datadryad.org/api/v1/journals`

Get details about a single journal:
`https://datadryad.org/api/v1/journals/{issn}`

Get a list of datasets associated with a journal (up to 2019-09-17):
`https://datadryad.org/api/v1/journals/{issn}/packages`

Additional query parameters that can be used to modify the
results returned for the above calls:
- `count` specifies the number of results per page.
- `date_from` and `date_to` can filter results to packages released in a date range.
- `cursor` can be used to specify the key used to start the results page.
