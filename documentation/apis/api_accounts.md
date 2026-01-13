Dryad API Accounts
==================

An API account is required to use advanced features of Dryad's APIs.

Obtain a Dryad API account
--------------------------

Before you can submit from the API, you must have a Dryad account and an account for the API.

1. First you must create a Dryad account, using an ORCID login,through the Dryad
web interface. 
2. Log in to Dryad at least once to create a user record and (if
applicable) associate it with your associated campus/organization.
3. You may then create an API account using the interface on your [_My account_](https://datadryad.org/account) page

In some cases, such as for association with a journal publishing system, an API account will be needed that is not attached to a single user. In this case, the account will not be associated with an ORCID, and will not be able to log in to the Dryad web interface. For such a use, please [contact us](mailto:help@datadryad.org) to request API access. In your request, please specify whether you are associated with an institution or journal that is a Dryad member, and provide the email address that will receive API account notifications.


Get a token for making requests for secure parts of the API
-----------------------------------------------------------

Before making secure requests to the Dryad API, you'll need a token. Currently our tokens last 10 hours and a token will need to be renewed when it expires. You may get a token from your account page in the web interface, or by using these examples from a few programming environments. Replace &lt;bracketed&gt; items with the values associated with your API account. For testing, you may choose to use a bash shell, a programming environment or a tool such as Postman.


```bash
# get token with curl
curl -X POST https://datadryad.org/oauth/token -d "client_id=<application-id>&client_secret=<secret>&grant_type=client_credentials" -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8"
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

### Renewing your token

Tokens are only valid for a limited amount of time. See documentation
about [retrying_requests made with expired tokens](retrying_expired.md) for more information.


Test that your token works
--------------------------

Now make sure you can use your token to access secured areas of the API. Test with some code like the following.

```bash
curl -i -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -X GET https://<domain>/api/v2/test
```

or

```ruby
# this Ruby example continues from the section above and assumes the variables above are already set
headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{token}" }

resp = RestClient.get "https://#{domain_name}/api/v2/test", headers

j = JSON.parse(resp)
```

You should see a 200 response and some information something like:

{"message" => "Welcome application owner &lt;name&gt;", "user_id" => &lt;number&gt;}


Perform API calls, such as download a dataset
---------------------------------------------

An authentication token may be added to any API call. Some API calls, such as creating a new dataset and downloading files, require a token for any call. Other calls, such as searching for datasets, will behave differently when a token is included.

When including a token in a call, access will be granted to more datasets. Without a token, only published datasets will be available. With a token, datasets created by the token's owner will also be available, as well as datasets that the owner may access through their permissions. 

```bash
curl -L -O -J -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -X GET https://<domain>/api/v2/datasets/<encoded_doi>
```
