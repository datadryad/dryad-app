Shibboleth Single Sign-On (SSO)
===============================

Dryad uses Shibboleth to validate that users are affiliated with member
institutions. 

Information on setting up shibboleth at a member institution is available in the "welcome packet" that Dryad sends to new members.

Authentication options
======================

Everyday login takes place using a researcher’s ORCID.  However on the first
sign in the user is asked if their institution is a Dryad member institution and
normally they log into their single sign on (InCommon/Shibboleth) then.  

When the user has done this once, they’re no longer prompted for this again on
other logins (just the ORCID login).  (Though we’ve talked about making this a
periodic re-validation such as yearly to ensure our user data doesn’t go stale.) 
 
Current Validation Methods (most to least preferred)
1. **InCommon/Shibboleth** – as described above.
2. **IP Address validation** – In this scenario an institution can give us IP
  address ranges.  Rather than validating with an institutional login for the
  first time, we then validate the IP address falls in the correct range.  If
  they’re not in the correct IP address range they get a message telling them that
  they need to use a campus network for their first login to the service. If
  successful, it shows they’ve validated and logged in successfully from that
  campus.  The downside of this method is keeping the IP address ranges up to date
  if they change and it’s a little broader validation. 
3. **One of the authors belongs to us**  --  In this method, anyone can claim to
  be a member of a campus community without validation.  However, in order to get
  a free deposit, the chosen affiliation of at least one author needs to match the
  chosen user-account affiliation.  If an author affiliation doesn’t match the
  asserted member affiliation then the depositing author will still be invoiced
  and asked to pay on publication.  I think we have only used this with one other
  institution and it is the least preferred of the 3 options. 
 


Technical details
=================

Rack "hack" for omniauth and ORCID login
----------------------------------------

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

