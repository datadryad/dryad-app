#Authorization Code Grant

Need to add more based on https://alexbilbie.com/guide-to-oauth-2-grants/ but these are the basics.

## Step 1: Get Authorized by User

Info needed
- client_id (this is the Application Id)
- redirect_uri (where to go back after done logging in)
- response_type=code

Get request to 

```ruby
https://<domain>/oauth/authorize?<put-key-values-above-into-url>
```

You should then get an authorization code back at the redirect_uri (I believe)

## Step 2: Get Access Token

Info needed
- client_id (Application Id)
- client_secret (secret)
- grant_type=authorization_code
- code (authorization code you got in step 1)
- redirect_uri (must be the same value as above)

Send POST request like
```bash
curl -X POST https://<domain>/oauth/token \
 -d "client_id=<client_id>&client_secret=<c-secret>&grant_type=authorization_code&code=<code>&redirect_uri=<url>" \
 -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8"
```

You'll get a token back in Json 

## Step 3: Use the token you get back as the bearer token for making requests

Example:

```bash
curl -X GET "http://localhost:3000/api/v2/test" -H "Authorization: Bearer 95DVpGX7C3xFTHZiFRNKJwSherohOIfYcDo1vIFUr-A"
```