Banner Widget API
=======================

This API provides banner images that can be used on external websites
to link to Dryad content using the DOI of an article. There are two
endpoints:
* `bannerForPub` returns an image, which is either a "Data in
  Dryad" button or a transparent pixel. It can be embedded in a page,
  and will either display the button or nothing (the transparent
  pixel), based on the presence of corresponding data in Dryad.
* `dataPackageForPub` redirects to the Dryad data package that
  is associated with the given article DOI.

These two calls can be combined to create a clickable image that only
appears on a page when the given article DOI has a corresponding data
package in Dryad.

GET /widgets/bannerForPub
============================

When making a GET request to
http://datadryad.org/widgets/bannerForPub, it will respond with an
image.  If the provided Article identifier (parameter `pubId`) is
linked to a data package in Dryad, the response is the 'Data in Dryad'
image banner.  If the Article identifier is not found, the pipeline
returns a 1x1 transparent gif.

Parameters:
* `pubId`: an article DOI or PubMed ID. The identifier may
  be expressed with a prefix of "pmid:", "doi:", or
  "http://dx.doi.org/". The identifier must be URL-encoded. Example:
  `doi%3A10.1186%2F1471-2148-12-60`
* `referrer`: a self-created identifier for the tool/entity using the
    widget, URL encoded. Required, but not currently used in
    determining the response.  This code is logged internally so Dryad
    can provide statistics related to use of the widget. Examples:
    BMC, Elsevier, JournalOfDataSharing

GET /widgets/dataPackageForPub
================================

When making a GET request to
http://datadryad.org/widgets/dataPackageForPub, the
server responds with a redirect to the Dryad Data Package resource
page (e.g., http://datadryad.org/resource/doi:10.5061/dryad.8h5p7p00)
if there is a data package in Dryad for the provided article
`identifier`, and to an empty page (HTTP 404) otherwise.

Parameters:
* `pubId`: an article DOI or PubMed ID. The identifier may be
  expressed with a prefix of "pmid:", "doi:", or
  "http://dx.doi.org/". The identifier must be
  URL-encoded. Example: `doi%3A10.1186%2F1471-2148-12-60`
* `referrer`: an identifier for the tool/entity using the widget, URL
    encoded. Required, but not currently used in determining the
    response. This code is logged internally so Dryad can provide
    statistics related to use of the widget. Examples: BMC, Elsevier,
    JournalOfDataSharing

Usage
=========

As an example, the widget can be constructed to automatically display
a linked banner if Dryad has data for the article
`doi:10.1186/1471-2148-12-60` as follows:

```
<a
href="http://datadryad.org/widgets/dataPackageForPub?referrer=BMC&pubId=doi%3A10.1186%2F1471-2148-12-60">
<img
src="http://datadryad.org/widgets/bannerForPub?referrer=BMC&pubId=doi%3A10.1186%2F1471-2148-12-60"
alt="Data in Dryad" />
</a>
```
