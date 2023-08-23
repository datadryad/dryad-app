
Embedding Dryad's Submission into a Manuscript System
=====================================================

Dryad's API allows manuscript processing systems to embed Dryad
submissions directly into their process. Sample API calls are shown
below, but for full details on the API options see the
[submissions](submission.md) document and the
[API documentation](https://datadryad.org/stash/api).

Though the API allows for some flexiblity in the workflow, Dryad's
preferred workflow is described below.

Prerequisites
-------------

- The manuscript processing system must have an API account with Dryad.
- The API account must have administrative access for all journals
  that will be processing submissions.
  

Initialize the Dryad deposit
----------------------------

To initialize a Dryad data deposit, the manuscript system should make
an initial call with the API credentials to obtain a token. Note that
this call does not need to be repeated for each submission; a token
can be used for as many authors/datasets as needed until it expires.

A sample call and result:
```bash
> curl -X POST https://datadryad.org/oauth/token -d "client_id=16b0c3c4f7916e2c9ba54d8&client_secret=493f95b1e5443c0b77d23f6&grant_type=client_credentials" -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8"

{"access_token":"Qa84cd6uhxC8U_Z8LOKpb0svA_pR5hse5dqaVQtWc","token_type":"Bearer","expires_in":35999,"created_at":1601647027}
```

Then, when the user invokes an action in the manuscript system such as
'Create Dryad Data Submission', use the token to issues a `POST` call
to `/datasets` with the initial dataset metadata. When a manuscript
system is making this call on behalf of an author, the dataset *must*
include:
- ISSN of the journal. This allows journal administrators (including
  the manuscript system) to view private information about the dataset in Dryad.

It also *should* include:
- a `userId` with the ORCID of the author that has been submitting
  the manuscript. This allows the author to manage the dataset in Dryad.
- an entry in the `authors` list that contains the ORCID of the
  submitting author

If the manuscript system is unable to provide an ORCID for the
submitting author, the `userId` *should* be set to "0". In this case,
the author will be required to login to the ORCID system before taking
control of the dataset.

When Dryad replies to this API call, the response will include a
summary of the deposit, including:
- the DOI for the dataset (`identifier`)
- a URL for making edits to the dataset (`editLink`)

A sample call using the [sample dataset file](sample_dataset.json), with results abbreviated for readability:
```bash
> curl --data "@sample_dataset.json" -i -X POST https://datadryad.org/api/v2/datasets -H "Authorization: Bearer <token>" -H "Content-Type: application/json"

{
  "_links": {
    "self": {
	  "href": "/api/v2/datasets/doi%3A10.7959%2Fdryad.83bk3jc0"
	},
	"stash:version": {
	  "href": "/api/v2/versions/320"
	},
  },
  "identifier": "doi:10.7959/dryad.83bk3jc0",
  "id": 296,
  "title": "Data from: Testing for unequal rates of morphological diversification in the absence of a detailed phylogeny: case study from characiform fishes",
  "authors": [
    {
	  "firstName": "Brian",
	  "lastName": "Sidlauskas",
	  "email": "brian_sidlauskas@somewhere.com",
	  "affiliation": "Oregon State University",
	  "affiliationROR": "https://ror.org/00ysfqy60",
	  "orcid": "0000-0003-0597-4085"
	}
  ],
  "abstract": "This study develops the random phylogenies rate test (RAPRATE)....",
  "keywords": [ "Cat","Computer", "Noodlecast", "Intercropping"	],
  "methods": "My cat will help you to discover why you can't get the data to work.",
  "relatedWorks": [
    {
	  "relationship": "article",
	  "identifierType": "DOI",
	  "identifier": "10.1111/j.1558-5646.2007.00022.x"
	}
  ],
  "versionNumber": 1,
  "versionStatus": "in_progress",
  "curationStatus": "In Progress",
  "lastModificationDate": "2020-10-02",
  "visibility": "restricted",
  "userId": "0000-0003-0597-4085",
  "license": "https://creativecommons.org/publicdomain/zero/1.0/",
  "editLink": "/stash/edit/doi%3A10.7959%2Fdryad.83bk3jc0"
  }
```

Allow users to edit metadata about the dataset, and upload data files
---------------------------------------------------------------------

The manuscript system can now redirect the author to Dryad by opening
the `editLink`. This URL may be opened in a new browser tab, or
directly in the tab where the author has been editing their manuscript
submission.

The `editLink` by itself only contains the information necessary to
open the item for editing in Dryad. In most cases, it will be
necessary to direct the user back to the manuscript system after the
Dryad submission has been completed. To instruct Dryad where to redirect
after a submission is completed, append the parameter `returnURL` to
the URL provided in the `editLink`. For example:

`<editLink>?returnURL=https%3A%2F%2Fmanuscriptomatic.org%2Fsubmission%2Fabc123`

The author will then proceed through the normal Dryad submission
process. They will be able to edit metadata that has been
pre-populated by the journal, and upload any files.

When the data submission is complete, the author will be redirected
back to the correct page in the manuscript system. If you have chosen
to open the Dryad submission in a new window, and you want the new
window to simply close, specify the `returnURL` as a page that closes
itself immediately upon opening. (See the
[demo closing page](embedded_submission_demo_close.html).) 

Obtain Dryad metadata
---------------------

Once the dataset has been submitted, the manuscript system can obtain
information about the dataset at any point by making an `GET` call to
`/datasets`. Information that may be the most useful includes:
- `title`
- `versionStatus` -- Whether this version of the dataset is being
  edited by an author (`in_progress`), is being processed internally by Dryad (`processing`), or has completed processing (`submitted`)
- `curationStatus` -- Status of the dataset in Dryad's curation workflow (e.g., `Private for peer review`, `Curation`, `Published`)
- `storageSize` -- total size of the dataset
- `sharingLink` -- for editors and reviewers to download the dataset
- `editLink` -- for authors to the contents of the dataset

Sample call and (abbreviated) response:
```
> curl -i -X GET https://datadryad.org/api/v2/datasets/doi%3A10.7959%2Fdryad.83bk3jc0 -H "Authorization: Bearer vdJVyt5Xt-Q7qemo3U" -H "Content-Type: application/json"

{
  "_links": {
    "self": {
	  "href": "/api/v2/datasets/doi%3A10.7959%2Fdryad.83bk3jc0"
	},
	"stash:version": {
	  "href": "/api/v2/versions/320"
	},
  },
  "identifier": "doi:10.7959/dryad.83bk3jc0",
  "id": 296,
  "storageSize":17116,
  "title": "Data from: Testing for unequal rates of morphological diversification in the absence of a detailed phylogeny: case study from characiform fishes",
  "authors": [
    {
	  "firstName": "Brian",
	  "lastName": "Sidlauskas",
	  "email": "brian_sidlauskas@somewhere.com",
	  "affiliation": "Oregon State University",
	  "affiliationROR": "https://ror.org/00ysfqy60",
	  "orcid": "0000-0003-0597-4085"
	}
  ],
  "abstract": "This study develops the random phylogenies rate test (RAPRATE)....",
  "keywords": [ "Cat","Computer", "Noodlecast", "Intercropping"	],
  "methods": "My cat will help you to discover why you can't get the data to work.",
  "relatedWorks": [
    {
	  "relationship": "article",
	  "identifierType": "DOI",
	  "identifier": "10.1111/j.1558-5646.2007.00022.x"
	}
  ],
  "versionNumber": 1,
  "versionStatus": "submitted",
  "curationStatus": "Submitted",
  "lastModificationDate": "2020-10-02",
  "visibility": "restricted",
  "sharingLink":"https://datadryad.org/stash/share/OI-tU-WmoT3I2KCOqX7Of624",
  "userId": 37182,
  "license": "https://creativecommons.org/publicdomain/zero/1.0/",
  "editLink": "/stash/edit/doi%3A10.7959%2Fdryad.83bk3jc0"
  }
```

Since datasets in Dryad may be modified at any time by the author or
Dryad curators, it is best if the API call is made on any screen that
will display Dryad information, to ensure the latest information is
being shown.

Provide status updates to Dryad
--------------------------------

The manuscript system should notify Dryad whenever there is a major
change to the manuscript's status, so Dryad may update the status of
the dataset. This includes:
- Manuscript Accepted
- Manuscript Rejected (or Withdrawn)

Submitting updates is accomplished by sending a PATCH request to
/api/v2/datasets/&lt;encoded-doi&gt; with some json patch information
that tells the server to set the /curationStatus value:

```json
[
	{ "op": "replace", "path": "/curationStatus", "value": "submitted" }
]
```

The value may be:
- `submitted` -- when a manuscript is accepted, and the dataset should be moved from "Private for peer review" into a "Submitted" status, ready for curation
- `withdrawn` -- when a manuscript is rejected or withdrawn, and the dataset should be moved from "Private for peer review" into a "Withdrawn" status, so the author may resubmit it in the future

You also need to set the Content-Type header to 'application/json-patch+json'

For the cURL example, please save a file called my_patch.json with the patch content shown above.

```bash
curl --data "@my_patch.json" -i -X PATCH "https://<domain-name>/api/v2/datasets/<encoded-doi>" -H "Authorization: Bearer <token>" -H "Content-Type: application/json-patch+json" -H "Accept: application/json"
```

Linking a dataset to a journal, or unlinking a dataset from a journal
---------------------------------------------------------------------

To link/unlink a dataset and a journal, use a similar approach to the status updates described above. The only difference is that the path should be `publicationISSN`, and the value is either the journal's ISSN (in the case of linking), or an empty string (to unlink). For example, to link journal ISSN "1234-5678" with a dataset, submit the following as the contents of the PATCH call:

```json
[
	{ "op": "replace", "path": "/publicationISSN", "value": "1234-5678" }
]
```

