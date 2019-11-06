# Renewing expired OAuth2 access tokens

OAuth2 tokens do not have an unlimited lifespan and must be renewed occasionally.
When you are granted a token, you will see some information such as this:

```
{"access_token"=>"c1ec...2fec", "token_type"=>"Bearer", "expires_in"=>36000, "created_at"=>1552520063}
```

The *expires_in* indicates how long the token is granted to you.  After that
you will need to get a new token.

The easiest way to handle an expired token is to add retry logic for your
requests and attempt getting a new token if the previous one has expired
and you get a *401: Unauthorized* http status code.

This means you will want to build *limited* retry logic into your application.

- You will receive a *401: Unauthorized* http status code after the token has expired.
- This is the same status code you get if you had a token that was never valid.
- You will want to get a new token and retry your request if it expired.
- You will want to retry *a limited number of times* in response to a 401
  status code since there may be other reasons for this status code such
  as having bad credentials.  You do not want to retry an infinite number
  of times since bad credentials will not be solved by retrying in that case.

The [retry client](retry_client.rb) shows an example of how to retry and
renew credentials.  The class also wraps some parts of the RestClient library
to avoid some repetitive code that is sent with most requests, but the main thing to note is the retry code.

Similar retry logic can be incorporated in most programming

```
# a method to retry a request that is passed in
def retry(method, *args)
  retries ||= 0
  # sample RestClient method to make a request, using current token
  RestClient.send(method, ... # not showing rest of call, but token is included
rescue RestClient::Unauthorized => ex
  raise ex unless get_token # raise exception if not able to get token
  retry if (retries += 1) < 3  # continue and retry request again if less than three tries
  raise ex # otherwise raise the exception, if over the retry limit for this request
end

# a method to renew a token
def get_token
  response = RestClient.post "#{scheme_host_port}/oauth/token", {
        grant_type: 'client_credentials',
        client_id: app_id,
        client_secret: secret
    }
    @token = JSON.parse(response)['access_token']
end
 ```

You can use the example retry wrapper around rest-client to make a request.
Retries and initially obtaining a token are transparent and do not need to be done
before making a call since the retry method handles obtaining a new token or
retrying on an Unauthorized status.


```
require_relative 'retry_client'
rc = RetryClient.new(
          app_id: '<your-app-id>',
          secret: '<your-secret>',
          scheme_host_port: 'https://dryad-stg.cdlib.org')
response = rc.retry(:get, '/api/v2/test', {}) # params are HTTP method, path and extra headers
=> <RestClient::Response 200 "{\"message\":..."> # response object returned
```

