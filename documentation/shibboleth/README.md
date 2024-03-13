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


Installing shibboleth service provider
======================================


Install the basic service provider daemon
-----------------------------------------

```
sudo yum update -y
```

- create a repo file for the shibboleth package under `/etc/yum.repos.d/shibboleth.repo` and include the contents from this [link](https://shibboleth.net/downloads/service-provider/RPMS/) (choose Amazon Linux 2023 from the first dropdown and hit generate)
- run `sudo yum install shibboleth.x86_64` (make sure the .x86_64 version is used)
- enable the service: `sudo systemctl enable shibd.service`
- run via `sudo systemctl start shibd`
- even though it's "running", it probably didn't start correctly due to certificate issues (which we fix below) -- check in `/var/log/shibboleth`

Configuration
- Update the contents of `/etc/shibboleth/shibboleth2.xml`
  - copy the initial file from the one in this directory
  - make sure the email address is set to `admin@datadryad.org`
  - make sure the `entityID` has the correct value
  - double-check the `SSO` section below and the url attached
- Update the apache configs (uncomment relevant sections)
  - under `/etc/httpd/conf.d`, there is a `shib.conf`, as well as a `datadryad.org.conf` 
  - look out for the `cgi-bin` section
- copy the `inc-md-cert-mdq.pem` from this directory to `/etc/shibboleth`

Certificate generation (the shibboleth certificate should *not* be the same as the web server certificate)
```
cd /etc/shibboleth
sudo ./keygen.sh -o ~/tmp -h sandbox.datadryad.org -y 15 -e https://sandbox.datadryad.org/shibboleth -n sp
sudo chmod a+r sp-key.pem   # key must be readable by the shibd process
sudo systemctl restart shibd
```
Now check `/var/log/shibboleth` again for any errors, to ensure the process started correctly.
