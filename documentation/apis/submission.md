Dryad Submission API
====================

The Dryad Submission API enables submission and update of datasets.  For authentication, it uses an OAuth2 client credentials grant (see [A Guide To OAuth 2.0 Grants](https://alexbilbie.com/guide-to-oauth-2-grants/)).

This document gives practical information for working with the API in order to submit a dataset and [fuller API documentation is available](https://datadryad.org/stash/api).


## Obtain an API Account

Before using the submission API, each user must have an [API Account](api_accounts.md).


## Create metadata for the dataset

Create the appropriate metadata. A sample of the bare minimum metadata
is shown below, but typical metadata should be more complete:

```
  {
    "title": "Visualizing Congestion Control Using Self-Learning Epistemologies",
    "authors": [
      {
        "firstName": "Wanda",
        "lastName": "Jackson",
        "email": "wanda.jackson@example.com",
        "affiliation": "University of the Example"
      }
   	 ],
    "abstract": "Cyberneticists agree that concurrent models are an interesting new topic, and security experts concur."
  }
```

See the [dataset metadata](dataset_metadata.md) page for a complete
description of the available fields.


## Create a new in-progress dataset

The first real step is to create a new in-progress dataset. 

After a successful dataset POST, you should see the dataset created with your metadata, an id (DOI identifier) and a versionStatus of 'in_progress'

For the cURL example, create a file called my_metadata.json that contains your json for the descriptive metadata to send with cURL.

```bash
curl --data "@my_metadata.json" -i -X POST https://<domain-name>/api/v2/datasets -H "Authorization: Bearer <token>" -H "Content-Type: application/json"
```
Or

```ruby
# the Ruby example builds on previous examples and assumes those previous variables are defined
metadata_hash =
  {
    "title": "Visualizing Congestion Control Using Self-Learning Epistemologies",
    "authors": [
      {
        "firstName": "Wanda",
        "lastName": "Jackson",
        "email": "wanda.jackson@example.com",
        "affiliation": "University of the Example"
      }
   	 ],
    "abstract": "Cyberneticists agree that concurrent models are an interesting new topic in the field of machine learning, and security experts concur."
  }
resp = RestClient.post "https://#{domain_name}/api/v2/datasets", metadata_hash.to_json, headers
# you should see a 201 response here

# to see information about the dataset created
return_hash = JSON.parse(resp)

# If you want to see a pretty version, use pretty-print--require 'pp' and pp(return_hash).
# Some of the main things to notice (besides the metadata you submitted) is the id and
# versionStatus are set.  We'll save the doi for later use.

# we'll use the DOI later
doi = return_hash['id']
doi_encoded = URI.escape(doi)
```

## Add data file(s) to your dataset

You may upload multiple files for your dataset. Only all direct file uploads or all URLs may be used within a single submission. But you may create a new version of the submission with another batch of files to use a different method of getting them into the system.

### Direct file upload

Find a file on your file system to upload, get its path and determine its Content-Type.  You would send it to the server like the example below by changing the file\_path and content\_type values.

For direct file uploads, do a PUT to {{url-domain-name}}/api/v2/datasets/{{doi_encoded}}/files/{{filename-encoded}} and the body being sent would be the binary file.  Set the HTTP "Content-Description" header to add a short description.  Set the HTTP Content-Type appropriately for the file type (for example image/jpeg).

```bash
curl --data-binary "@</path/to/my/file>" -i -X PUT "https://<domain-name>/api/v2/datasets/<encoded-doi>/files/<encoded-file-name>" -H "Authorization: Bearer <token>" -H "Content-Type: <mime-type>" -H "Accept: application/json"
```

Or

```ruby
# The Ruby example builds on previous examples and assumes those previous variables are defined

# In this Ruby example, change the file_path to a file that exists on your system.
# Also, please set the 'Content-Type' to to accurately represent the mimetype such
# as from lists like https://www.freeformatter.com/mime-types-list.html .

# If you wish to change the filename to something different than the existing filename
# you may do so.

file_path = '/Users/my_user/Desktop/red_stapler.gif'
file_name = URI.escape(File.basename(file_path))
content_type = 'image/gif'

resp = RestClient.put(
  "https://#{domain_name}/api/v2/datasets/#{doi_encoded}/files/#{file_name}",
  File.read(file_path),
  headers.merge({'Content-Type' => content_type})
)

# A successful response will be a 201 and you should receive a json response
# with information about the file uploaded including the path, size, mimetype and status.

return_hash = JSON.parse(resp)
```

After a file upload you will get a digest and digestType back in the JSON.  You can check this against your local file to be certain it was uploaded correctly if you wish.
The other method is adding by URL.  You can do a POST to {{url-domain-name}}/api/v2/datasets/{{doi_encoded}}/urls with json something like the following:

### Upload by URL reference

To upload a file that is referenced by URL, do a POST to `{{url-domain-name}}/api/v2/datasets/{{doi_encoded}}/urls` with json something like the following:

```
{
    "url": "https://raw.githubusercontent.com/CDL-Dryad/dryad-app/main/documentation/apis/submission.md",
    "digest": "aca3032d20c829a6060f1b90afda6d14",
    "digestType": "md5",
    "description": "This is the best file ever!",
    "size": 1234,
    "path": "api_submission.md",
    "mimeType": "text/plain",
    "skipValidation": true
}
```

This will add entries to the database with the information you specify.  Only the `url` is required. Other fields, which are optional, are described below:

- `path` can provide a filename when the name is not specified in the URL (this is common when the URL is using an identifier string rather than a file name)
- `digest` and `digestType` are not required, but if they are added then they will be passed as part of the ingest manifest to Merritt. If the digest doesn't match when Merritt downloads the files from the internet, then Merritt will cause an error on ingesting and you'll need to check/fix it.
- `skipValidation`, if true, will tell DASH to skip the step of validating the existence of the file

## Submit your dataset

After adding the descriptive metadata and any files, you're ready to
submit your dataset for curation.

Submitting is accomplished by sending a PATCH request to
/api/v2/datasets/&lt;encoded-doi&gt; with some json patch information
that tells the server to set the /versionStatus value to
'submitted': 

```json
[ { "op": "replace", "path": "/versionStatus", "value": "submitted" } ]
```
You also need to set the Content-Type header to 'application/json-patch+json'

For the cURL example, please save a file called my_patch.json with the patch content shown above.

```bash
curl --data "@my_patch.json" -i -X PATCH "https://<domain-name>/api/v2/datasets/<encoded-doi>" -H "Authorization: Bearer <token>" -H "Content-Type: application/json-patch+json" -H "Accept: application/json"
```
Or

```ruby
# The Ruby example builds on previous examples and assumes those previous variables are defined
body = [ { "op": "replace", "path": "/versionStatus", "value": "submitted" } ].to_json

resp = RestClient.patch(
  "https://#{domain_name}/api/v2/datasets/#{doi_encoded}",
  body,
  headers.merge({'Content-Type' =>  'application/json-patch+json'})
)

# A successful response will be a 202 and you should receive a json response
# with information about the submission.  You may continue to do GET requests
# on the dataset /api/v2/datasets/<encoded-doi> to see the status changes until
# a successful ingest which will be 'submitted'.

return_hash = JSON.parse(resp)
```

For an explanation of other `versionStatus` values, see the [Submission
flow](../submission_flow.md) document.

## Retaining a dataset in a private status for peer review purposes

This step is optional.

By default, datasets that are submitted are immediately eligible for
curation. Dryad curators may evaluate and publish `submitted` datasets at any
time. If you wish your dataset to remain private until an associated article is
published, you may update the dataset's `curationStatus` to indicate this.

To move a dataset into `peer_review` status, the dataset must have a
`versionStatus` of `submitted`. Make a PATCH request as described
above. Submit to /api/v2/datasets/&lt;encoded-doi&gt; with some json patch information
that tells the server to set the /curationStatus value to
'submitted': 

```json
[ { "op": "replace", "path": "/curationStatus", "value": "peer_review" } ]
```

Datasets in `peer_review` status will remain uncurated and unpublished until
Dryad learns the associated article has been published. Reminders will
occasionally be sent to the submitter.

For an explanation of other `curationStatus` values, see the [Submission
flow](../submission_flow.md) document.

## Revise your metadata in a new version

After you've successfully submitted your dataset and seen the dataset
become available ('submitted' value for the versionStatus), you decide
to expanded your metadata to include more of the details described in
the [dataset metadata](dataset_metadata.md) examples.

To modify a dataset, do a PUT request to the /datasets/<encoded-doi> URL:

```ruby
# this example continues the ones from above and asumes you already have variables defined

resp = RestClient.put "https://#{domain_name}/api/v2/datasets/#{doi_encoded}", metadata_hash.to_json, headers
# You will see a 200 response code if all is well.
```

Once staging is complete and to submit the changes to your dataset,
please follow the "Submit your dataset" instructions again from the
section above to submit this new version of your dataset.

In addition to changing your metadata, you may also add additional
files before re-submitting the updated version of your dataset.

## Moidifying internal metadata fields

Dryad maintains some "internal" fields separately from the descriptive
dataset metadata. Although these can be modified by changing the
dataset metadata, they can also be manipulated independently.

Fields that have single values (set_internal_datum):
- publicationISSN
- manuscriptNumber

Field that allow multiple values (add_internal_datum):
- mismatchedDOI
- formerManuscriptNumber
- duplicateItem

### As an aggregate

The internal metadata can be manipulated using either the internal id of a version, or a dataset id:
- GET /internal_data/{id}
- PUT /internal_data/{id}
- DELETE /internal_data/{id}
- GET /datasets/{dataset_id}/internal_data
- POST /datasets/{dataset_id}/internal_data

### As individual fields

You can POST request to either `api/datasets/<id>/add_internal_datum` or `api/datasets/<id>/set_internal_datum`, depending on the type of data. The body should be JSON in the form of `{"data_type":"mismatchedDOI","value":"223342”}`

## Curation history information

Superusers can view and modify the curation history associated with a
dataset.

- GET /datasets/{dataset_id}/curation_activity
- POST /datasets/{dataset_id}/curation_activity

Curation activity does lock down a few fields: the `identifier_id` is
set by the `dataset_id` on creation and can’t be modified by
PUT. Similarly, the `user_id` is set to the api user that creates the
record and can’t be modified by PUT. 

