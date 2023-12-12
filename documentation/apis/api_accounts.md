Dryad API Accounts
==================

An API account is required to use advanced features of Dryad's APIs.

Obtain a Dryad API account
--------------------------

Before you can submit from the API, you must have an account for the
API. It is easiest if you first create an account through the Dryad
web interface. Dryad staff can then add API capabilities to this
account. Log in to Dryad at least once to create a user record and (if
applicable) associate it with your associated campus/organization.

In some cases, an API account will be needed that is not attached to a
single user. In this case, the account will not be associated with an
ORCID, which means that the API account will not be able to log in to
the Dryad web interface. We will still need an email address to
receive notifications associated with the account.

Please [contact us](mailto:help@datadryad.org) to request API access. In your
request, please specify whether you are associated with an institution
or journal that is a Dryad member. Dryad developers will then [grant
you the necessary permissions](adding_api_accounts.md).


Get a token for making requests for secure parts of the API
-----------------------------------------------------------

Before making secure requests to the Dryad API, you'll need a token.  Currently our tokens last 10 hours and a token will need to be renewed when it expires.  You may get a token using these examples from a few programming environments.  Replace &lt;bracketed&gt; items with the values you were given.  For testing, you may choose to use a bash shell, a programming environment or a tool such as Postman.


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

Tokens are only valid for a limited amount of time.  See documentation
about [retrying_requests made with expired tokens](retrying_expired.md) for more information.


Test that your token works
--------------------------

Now make sure you can use your token to access secured areas of the API.  Test with some code like the following.

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
