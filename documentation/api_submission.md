# Doing a basic submission and an version update with the Dryad API
The Dryad API now enables submission.  For authentication, it uses an OAuth2 client credentials grant (see [A Guide To OAuth 2.0 Grants](https://alexbilbie.com/guide-to-oauth-2-grants/)).

This document gives practical information for working with the API in order to submit a dataset and [fuller API documentation is available](https://dash.ucop.edu/api/docs/index.html).

## Log in to Dryad and request a an application id and secret

Before you can submit from the API, you need to log in to Dryad at least once to create a user record.  You may log in to your associated campus/organization or use the DataONE login with your Google login credentials.

To request access, please [contact us](mailto:uc3@ucop.edu).

## Get a token for making requests for secure parts of the API
Before making secure requests to the Dryad API, you'll need a token.  Currently our tokens last 10 hours and a token will need to be renewed if it expires.  You may get a token using these examples from a few programming environments.  Replace &lt;bracketed&gt; items with the values you were given.  For testing, you may choose to use a bash shell, a programming environment or a tool such as Postman.


```bash
# get token with curl
curl -X POST https://<domain-name>/oauth/token -d "client_id=<application-id>&client_secret=<secret>&grant_type=client_credentials" -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8"
```

Or

```ruby
# get token with Ruby
require 'rest-client'
require 'json'
app_id = '<application-id>'
secret = '<secret>'
domain_name = '<domain-name>'
response = RestClient.post "https://#{domain_name}/oauth/token", {
  grant_type: 'client_credentials',
  client_id: app_id,
  client_secret: secret
}
token = JSON.parse(response)['access_token']
```

## Test that your key works
Now make sure you can use your key to access secured areas of the API.  Test with some code like the following.

```bash
curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -X GET https://<domain>/api/test
```

or

```ruby
# this Ruby example continues from the section above and assumes the variables above are already set
headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{token}" }

resp = RestClient.get "https://#{domain_name}/api/test", headers

j = JSON.parse(resp)
```

You should see a 200 response and some information something like:

{"message" => "Welcome application owner &lt;name&gt;", "user_id" => &lt;number&gt;}

## Create a new in-progress dataset

The first real step is to create a new in-progress dataset.  Currently, only minimal required DataCite metadata is supported and fuller support will be added soon.  See the example below for example metadata supported.

After a successful dataset POST, you should see the dataset created with your metadata, an id (DOI identifier) and a versionStatus of 'in_progress'

For the cURL example, create a file called my_metadata.json that contains your json for the descriptive metadata to send with cURL.

```bash
curl --data "@my_metadata.json" -i -X POST https://<domain-name>/api/datasets -H "Authorization: Bearer <token>" -H "Content-Type: application/json"
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
resp = RestClient.post "https://#{domain_name}/api/datasets", metadata_hash.to_json, headers
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
## Dataset options

To see the dataset fields and option in use, see the [Sample Dataset Object](https://github.com/CDL-Dryad/dryad/blob/master/documentation/sample_dataset.json).

Useful options that control a dataset's behavior:
- `skipDataciteUpdate` - If true, doesn't send any requests to DataCite when registering the dataset. This is useful when the dataset already has a DOI, which is present in the metadata being submitted.
- `skipEmails` - If true, prevents emails from being sent to users on submission. Prevents emails regardless of whether the submission is successful or an error. Also stopps the emails that ask co-authors to register their ORCID. Does *not* stop the internal emails that are sent to Dryad admins if there is a submission error.
- `loosenValidation` - Allows a dataset to be processed even if author information is incomplete (e.g., missing affiliations), or if the abstract is missing. It does still perform some basic validation of the dataset.

The above settings get carried with a dataset into future API submissions, but the UI resets all of these values to `false` so that people can't avoid being good research citizens when they manually update their datasets. These settings are hidden when they're in the default (false) state to keep people from seeing them and trying to set them (since most people can't set them).

## Add data file(s) to your dataset

You may upload multiple files for your dataset. Only all direct file uploads or all URLs may be used within a single submission. But you may create a new version of the submission with another batch of files to use a different method of getting them into the system.

### Direct file upload

Find a file on your file system to upload, get its path and determine its Content-Type.  You would send it to the server like the example below by changing the file\_path and content\_type values.

For direct file uploads, do a PUT to {{url-domain-name}}/api/datasets/{{doi_encoded}}/files/{{filename-encoded}} and the body being sent would be the binary file.  Set the HTTP "Content-Description" header to add a short description.  Set the HTTP Content-Type appropriately for the file type (for example image/jpeg).

```bash
curl --data-binary "@</path/to/my/file>" -i -X PUT "https://<domain-name>/api/datasets/<encoded-doi>/files/<encoded-file-name>" -H "Authorization: Bearer <token>" -H "Content-Type: <mime-type>" -H "Accept: application/json"
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
  "https://#{domain_name}/api/datasets/#{doi_encoded}/files/#{file_name}",
  File.read(file_path),
  headers.merge({'Content-Type' => content_type})
)

# A successful response will be a 201 and you should receive a json response
# with information about the file uploaded including the path, size, mimetype and status.

return_hash = JSON.parse(resp)
```

After a file upload you will get a digest and digestType back in the JSON.  You can check this against your local file to be certain it was uploaded correctly if you wish.
The other method is adding by URL.  You can do a POST to {{url-domain-name}}/api/datasets/{{doi_encoded}}/urls with json something like the following:

### Upload by URL reference

To upload a file that is referenced by URL, do a POST to `{{url-domain-name}}/api/datasets/{{doi_encoded}}/urls` with json something like the following:

```
{
    "url": "https://raw.githubusercontent.com/CDL-Dryad/dryad/master/documentation/api_submission.md",
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

## Publish your dataset

After adding the descriptive metadata and any files, you're ready to publish your dataset.

Publication is accomplished by sending a PATCH request to /api/datasets/&lt;encoded-doi&gt; with some json patch information that tells the server to try and set the /versionStatus value to 'submitted' like below:

```json
[
	{ "op": "replace", "path": "/versionStatus", "value": "submitted" }
]
```
You also need to set the Content-Type header to 'application/json-patch+json'

For the cURL example, please save a file called my_patch.json with the patch content shown above.

```bash
curl --data "@my_patch.json" -i -X PATCH "https://<domain-name>/api/datasets/<encoded-doi>" -H "Authorization: Bearer <token>" -H "Content-Type: application/json-patch+json" -H "Accept: application/json"
```
Or

```ruby
# The Ruby example builds on previous examples and assumes those previous variables are defined
body = [ { "op": "replace", "path": "/versionStatus", "value": "submitted" } ].to_json

resp = RestClient.patch(
  "https://#{domain_name}/api/datasets/#{doi_encoded}",
  body,
  headers.merge({'Content-Type' =>  'application/json-patch+json'})
)

# A successful response will be a 202 and you should receive a json response
# with information about the submission.  You may continue to do GET requests
# on the dataset /api/datasets/<encoded-doi> to see the status changes until
# a successful ingest which will be 'submitted'.

return_hash = JSON.parse(resp)
```

## Revise your metadata in a new version

After you've successfully submitted your dataset and seen the dataset become available ('submitted' value for the versionStatus), you decide to expanded your metadata like the following set.

```ruby
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
        "abstract": "Cyberneticists agree that concurrent models are an interesting new topic in the field of machine learning, and security experts concur.",
        "funders": [
            {
                "organization": "Savannah River Operations Office, U.S. Department of Energy",
                "awardNumber": "12345"
            },
            {
                "organization": "The Cat Chronicles",
                "awardNumber": "cat383"
            }
        ],
        'methods': "My cat will help you to discover why you can't get the data to work.",
        "usageNotes": 'Use carefully and parse results underwater.',
        "keywords": [
            "Abnormal bleeding",
            "Cat",
            "Host",
            "Computer",
            "Log",
            "Noodlecast",
            "Intercropping"
        ],
        "relatedWorks": [
            {
                "relationship": "Cites",
                "identifierType": "URL",
                "identifier": "http://example.org/cats"
            },
            {
                "relationship": "isNewVersionOf",
                "identifierType": "URL",
                "identifier": "http://thedog.example.org/cats"
            }],
        "locations": [
            {
                "place": "Grogan's Mill, USA",
                "point": {
                    "latitude": "30.130379",
                    "longitude": "-95.402929"
                },
                "box": {
                    "swLongitude": "-95.527852",
                    "swLatitude": "30.049326",
                    "neLongitude": "-95.32743",
                    "neLatitude": "30.164696"
                }
            },
            {
                "point": {
                    "latitude": "37.0",
                    "longitude": "-122.0"
                }
            },
            {
                "box": {
                    "swLongitude": "-122.0",
                    "swLatitude": "37.0",
                    "neLongitude": "-121.0",
                    "neLatitude": "38.0"
                }
            }
        ]
    }
```

To modify your dataset you'll do a PUT request to the /datasets/<encoded-doi> URL for this dataset.

```ruby
# this example continues the ones from above and asumes you already have variables defined

resp = RestClient.put "https://#{domain_name}/api/datasets/#{doi_encoded}", metadata_hash.to_json, headers
# You will see a 200 response code if all is well.
```

Once staging is complete and to publish the changes to your dataset, please follow the "Publish your dataset" instructions again from the section above to publish this new version of your dataset.

In addition to changing your metadata, you could've added additional files before re-publishing this updated version of your dataset.

## Internal metadata fields

### As an aggregate

The internal metadata can be manipulated using either the internal id of a resource, or a dataset id:
- GET /internal_data/{id}
- PUT /internal_data/{id}
- DELETE /internal_data/{id}
- GET /datasets/{dataset_id}/internal_data
- POST /datasets/{dataset_id}/internal_data

### As individual fields

You can POST request to either `api/datasets/<id>/add_internal_datum` or `api/datasets/<id>/set_internal_datum`, depending on the type of data. The body should be JSON in the form of `{"data_type":"mismatchedDOI","value":"223342”}`

Fields that have single values (set_internal_datum):
- publicationISSN
- manuscriptNumber

Field that allow multiple values (add_internal_datum):
- mismatchedDOI
- formerManuscriptNumber
- duplicateItem

## Curation status information

- GET /resources/{id}/curation_activity

Curation activity does lock down a few fields: the identifier_id is set by the dataset_id on creation and can’t be modified by PUT. Similarly, the user_id is set to the api user that creates the record and can’t be modified by PUT.

