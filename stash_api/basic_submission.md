# Doing a basic submission and an version update with the Dash API
The Dash API now enables basic submission.  For authentication, it uses an OAuth2 client credentials grant (see [A Guide To OAuth 2.0 Grants](https://alexbilbie.com/guide-to-oauth-2-grants/)).

This document gives practical information for working with the API in order to submit a dataset.

API documentation is available at http://dash-dev.ucop.edu/api/docs/index.html .

## Log in to Dash and request a an application id and secret

Before you can submit from the API, you need to log in to Dash at least once to create a user record.  You may log in to your associated campus/organization or use the DataONE login with your Google login credentials.

To request access, please [contact us](mailto:uc3@ucop.edu).

## Get a token for making requests for secure parts of the API
Before making secure requests to the Dash API, you'll need a token.  Currently our tokens last 10 hours and a token will need to be renewed if it expires.  You may get a token using these examples from a few programming environments.  Replace &lt;bracketed&gt; items with the values you were given.  For testing, you may choose to use a bash shell, a programming environment or a tool such as Postman.


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

## Add data file(s) to your dataset

Find a file on your file system to upload, get its path and determine its Content-Type.  You would send it to the server like the example below by changing the file\_path and content\_type values.

You may upload multiple files for your dataset.

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