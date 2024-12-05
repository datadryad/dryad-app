Dryad APIs
============

This directory contains documentation for Dryad's various APIs.

Search API
---------------

The easiest API to use is the [Search API](search.md), which allows anonymous
users to locate datasets of interest. URLs for the Search API may be used in a
browser, or with many tools.

REST API and GET requests
-------------------------

The [REST API](https://datadryad.org/stash/api) allows detailed interaction
with Dryad contents. The most common case is to use GET requests to retrieve
information about datasets, versions, and files.

When using the API, any DOI included must be
[URL-encoded](https://www.w3schools.com/tags/ref_urlencode.ASP) to ensure correct processing.

Some examples:
- Listing of datasets: `https://datadryad.org/api/v2/datasets`
- Information about a dataset: `https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7`
- Versions of the dataset: `https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/versions`
- Files from a version: `https://datadryad.org/api/v2/versions/26724/files`
- Download the most recent version of a dataset: `https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.j1fd7/download`

# Authentication and accessing private content

To access more powerful features, an API account is required. API accounts allow users to:
- Access the API at higher rates
- Access datasets that are not yet public, but are associated with the account's community (institution, journal, etc.)
- Update datasets associated with the account's community

See the [API accounts](api_accounts.md) document for more information on requesting an API account and using it to access datasets.

# Submission

The [Submission API](submission.md) is used by systems that want to partner
more closely with Dryad and create dataset submissions directly.


Reporting API
-------------

Dryad maintains a variety of reports regarding its content.

- Reports that are automatically generated on a regular basis are available at `https://datadryad.org/api/v2/reports`
- Reports that are generated less frequently are available through our [Data about Dryad](https://github.com/datadryad/dryad-data/) repository


API Versioning
============

The Dryad API uses [Semantic Versioning](https://semver.org/) to track changes to the API. 

The current version of our API is `2.1.0`. This is also the only supported API versions, at the moment.

In order to use the latest API version, you can:
- Use `https://datadryad.org/api/v2/` as the base URL for all API requests.
- You can also send send the `X-API-Version: 2.1.0`

We added 2 new response headers:
- The `X-API-Version` header to allow clients to specify the version of the API they are using.
- The `X-API-Deprecation` header to notify clients if the version they are using is deprecated and will be removed in the future.

In case a bad version number is used, the API will respond with:
- `400` error status.
- `{ "error": "Unsupported API version: {requested-version}, latest version is: 2.1.0" }` in the response body.
- The `X-API-Version` header set to the version of the API you requested.
- The `X-API-Deprecation` header set `true`. This header will not be returned in case the version you are using is not deprecated.