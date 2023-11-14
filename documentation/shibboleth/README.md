# Shibboleth Single Sign-On (SSO)

Dryad uses Shibboleth to validate that users are affiliated with member
institutions. 

Information on setting up shibboleth at a member institution is available in the "welcome packet" that Dryad sends to new members.

# Technical details

## Rack "hack" for omniauth and ORCID login

See the file config/initializers/omniauth.rb . It has to be tricked into
generating https urls since the Apache reverse proxy presents all traffic to the
application as http, whether it really is or not and ORCID logins will fail if
they're not https on https sites. 

Basically, if it's ORCID login and it's not localhost or some other domain which
really do use http, then the https url has to be mashed in manually. So it seems
like you may not have to change it if the new servers are using https at the
apache level. You may need to add further exceptions if there are further test
servers which legitimately don't use SSL (like local servers, more containers or
whatever). 

