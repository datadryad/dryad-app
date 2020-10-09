
Dryad Search API
================

Dryad allows searching of datasets via a search API.

The basic call looks like:
```bash
curl "https://datadryad.org/api/v2/search?q=carbon"
```

A more complex call looks like:
```bash
curl "https://datadryad.org/api/v2/search?q=carbon&page=2&per_page=5"
```

Any combination of the following parameters may be used in a search:
- *q* -- a list of terms to be searched. If multiple terms are
  supplied, the default is to combine them with *AND*. Terms can also be
  combined with an explicitly-stated *OR*. Grouping and more complex
  operations may be performed according to the
  [Lucene Search Syntax](https://lucene.apache.org/core/2_9_4/queryparsersyntax.html).
- *page* -- which page of datasets to view. Defaults to page 1.
- *per_page* -- number of datasets to return on each page. Defaults
  to 10. Maximum allowed is 100.
- *affiliation* -- a *ROR* identifier specifying an institutional
  affiliation that must be present in the list of dataset authors. The
  identifier should be in the full "https" format and should be
  URL-encoded, e.g., `https%3A%2F%2Fror.org%2F00x6h5n95`
- *tenant* -- the abbreviation for a "tenant" organization in
  Dryad. This will automatically search all affiliations associated
  with the given tenant. If both a *tenant* and *affiliation* are
  specified, the tenant will be ignored.
- *modifiedSince* -- a timestamp for limiting results. Datasets will
  only be returned if that have been modified since the given
  time. The time must be specified in ISO 8601 format, and the time
  zone must be set to UTC, e.g., `2020-10-08T10:24:53Z`.


