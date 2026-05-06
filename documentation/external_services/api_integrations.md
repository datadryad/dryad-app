# API Integrations

Code for Dryad's integrations with external APIs is in [`lib/integrations`](https://github.com/datadryad/dryad-app/tree/main/lib/integrations)

`Integrations::Base` houses basic HTTP method interactions for JSON and XML APIs, which can be used by specific integrations.

## Crossref

`Integrations::Crossref` is used to query Crossref for article metadata. This can be imported into a dataset by `Stash::Import::Crossref`, and is also used to suggest article-dataset links by the publication updater.


## DataCite

`Integrations::Datacite` is used to register, update, and query datasets on DataCite, by scripts in [`lib/datacite`](https://github.com/datadryad/dryad-app/tree/main/lib/datacite) and `Stash::Import::Datacite`


## DOI.org

`Integrations::Doi` is used to retrieve citeproc JSON (basic citation metadata) for all DOIs, regardless of their issuer.


## Github

`Integrations::Github` is used for retrieving information about GitHub issues associated with specific datasets. The API is used with authorization tokens for the "Dryad issue tracker", an app owned by the [Dryad GitHub organization](https://github.com/datadryad) ([private settings page](https://github.com/organizations/datadryad/settings/apps))


## NIH and NSF

`Integrations::NIH` and `Integrations::NSF` handle requests to the NIH and NSF grant reporting APIs, for importing funding information for datasets.


## NCBI (PubMed)

Requests to the NCBI E-Utilities and other [NCBI APIs](https://www.ncbi.nlm.nih.gov/home/develop/api/) are handled through `Integrations::PubMed`