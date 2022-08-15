# Choosing the correct authentication type

The Dryad system currently supports two different OAuth2 industry-standard authentication
strategies for use with its API. Authentication isn't required for all operations but
is needed for higher-volume operations or in order to do more than only reading public
data.

## Client Credentials Grant

Client Credentials grant is one of the simplest ways to authenticate to the Dryad service
and it is the right choice when the Application requesting access doesn't need a specific
outside owner's permission in order to create or modify data. This grant type might be used in some of
these cases.

- Simply want an API account to increase rate limits of public data.
- The application requesting access owns all the data and is only requesting access
  for a specific user.
- The application requesting access has a special ownership or administrative 
  arrangement such as submitting preliminary data that a user may claim and
  obtain ownership of later.

## Authorization Code Grant

The Authorization Code grant is a familiar workflow when one web application wants to
obtain information from another service.  The process is already familiar from social media
sites that request access from other sites.

When an Authorization Code grant is used, the outside application (the one Dryad issues an Application Id
and secret to) redirects to a Dryad login process for a user. The user must supply credentials
and grant access for the non-Dryad application in order for that application to have access for
that user.

## Limitations for both types of access

When implementing either type of access, the outside application, registered with Dryad, is responsible
for keeping the secret private and not exposing the secret to the public. This means the
secret should not be embedded in source code distributed to users or exposed in client-side
Javascript. The secret would likely be used in server-side code to which users do not have
direct access to see or decompile credentials.

Please see these additional resources:

- See our information about [api accounts](api_accounts.md) which gives general starting
  information and describes a client credentials grant.
- See an example of working with an [authorization code grant](authorization_code_grant.md)
  which helps gets you started with this type of grant and walks through the process.
- See https://alexbilbie.com/guide-to-oauth-2-grants/ which is a useful description and
  helps in understanding possible OAuth 2 grants.