Shibboleth Single Sign-On (SSO)
===============================

Dryad uses Shibboleth to validate that users are affiliated with member
institutions. 

Information on setting up shibboleth at a member institution is available in the "welcome packet" that Dryad sends to new members.

Authentication options
======================

Everyday login takes place using a researcher’s ORCID. However on the first
sign in the user is asked if their institution is a Dryad member institution and
normally they log into their single sign on (InCommon/Shibboleth) then. 

When the user has done this once, they’re no longer prompted for this again on
other logins (just the ORCID login). (Though we’ve talked about making this a
periodic re-validation such as yearly to ensure our user data doesn’t go stale.) 
 
Current Validation Methods (most to least preferred)
1. **InCommon/Shibboleth** – as described above.
2. **IP Address validation** – In this scenario an institution can give us IP
  address ranges. Rather than validating with an institutional login for the
  first time, we then validate the IP address falls in the correct range. If
  they’re not in the correct IP address range they get a message telling them that
  they need to use a campus network for their first login to the service. If
  successful, it shows they’ve validated and logged in successfully from that
  campus. The downside of this method is keeping the IP address ranges up to date
  if they change and it’s a little broader validation. 
3. **One of the authors belongs to us**  --  In this method, anyone can claim to
  be a member of a campus community without validation. However, in order to get
  a free deposit, the chosen affiliation of at least one author needs to match the
  chosen user-account affiliation. If an author affiliation doesn’t match the
  asserted member affiliation then the depositing author will still be invoiced
  and asked to pay on publication. I think we have only used this with one other
  institution and it is the least preferred of the 3 options. 
 


Technical details
=================

Shibboleth authentication consists of two major pieces:
- Identity Provider (IdP) -- the service where a user logs in, typically at a university
- Service Provider (SP) -- the service that uses the login information, like Dryad


Rack "hack" for Omniauth and ORCID login
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


Shibboleth flow of control
--------------------------

- Dryad login screen sends users to the InCommon discovery service to locate
  info about the shibboleth IdP with the entityID that the user selected from the
  dropdown.
- InCommon (or the IdP?) directs users to our SP to initialize the
  transaction, with a URL like https://datadryad.org/Shibboleth.sso/Login, including the IdP entityID and a redirect URL
  - Apache detects that Shibboleth.sso is protected by mod_shib, so it hands control to the shibd process
- shibd sends to https://wayf.incommonfederation.org/DS/WAYF
   - IdP makes a SAML assertion and sends it back to shibd
   - Apache sees it's approved and forwards to puma
- Once login is complete, control goes back to https://datadryad.org/auth/shibboleth/callback,
  which is handled by Rails
  - In Rails `SessionsController.callback` handles the call,
    - verifyies the validity of the package sent from the IdP
    - redirects as appropriate


Installing Shibboleth Service Provider
======================================


Install the basic Service Provider daemon
-----------------------------------------

```
sudo yum update -y
```

Basic install
- Create a repo file for the shibboleth package under `/etc/yum.repos.d/shibboleth.repo` and include the contents from
  this [link](https://shibboleth.net/downloads/service-provider/RPMS/) (choose Amazon Linux 2023 from the first dropdown and hit generate)

```
sudo yum install shibboleth.x86_64 #(make sure the .x86_64 version is used)
sudo yum install shibboleth-embedded-ds
sudo systemctl enable shibd.service #enable the service
sudo systemctl start shibd
```

Even though it's "running", it probably didn't start correctly due to certificate issues (which we will fix below) -- check in `/var/log/shibboleth`

Ensure SELinux doesn't prevent Apache from working properly
- `sudo setsebool -P httpd_read_user_content 1`
- `sudo setsebool -P httpd_can_network_connect 1`

Configuration
- Update the contents of `/etc/shibboleth/shibboleth2.xml`
  - copy the initial file from the one in this directory
  - email address set to `admin@datadryad.org`
  - `entityID` has the correct value
  - handlerSSL="true"
- Copy the `inc-md-cert-mdq.pem` and `non_federation_metadata.xml` from this directory to `/etc/shibboleth`
- Copy `PrintShibInfo.pl` from this directory to `/var/www/cgi-bin`
- Update the apache configs 
  - copy `shib.conf`, `shibboleth-ds.conf` to  `/etc/httpd/conf.d`
  - edit `/etc/httpd/conf.d/datadryad.org.conf` to  uncomment the shibboleth sections


Certificate generation for InCommon
- The shibboleth certificate should *not* be the same as the web server's SSL certificate
- If you already have the same entityID on another server, don't make a new certificate, just copy the keys

```
cd /etc/shibboleth
sudo ./keygen.sh -h sandbox.datadryad.org -y 15 -e https://sandbox.datadryad.org -n sp
sudo chown shibd *.pem # keys must be readable by the shibd process
sudo chmod a+r sp-key.pem
```

Fix permissions for InCommon cache
```
sudo systemctl restart shibd
sudo chmod a+rx /var/cache/shibboleth/inc-mdq-cache
sudo systemctl restart shibd
```

Now check `/var/log/shibboleth` again for any errors, to ensure the process started correctly.


Additional config
-----------------

- attribute-map.xml
  - Maps the field specififed by "name" attribute from the provider's assertion to field specified by "id" attribute in our metadata
- non_fedaration_metadata.xml
  - Specifies locations and properties for IdPs that are not managed by InCommon
- `/etc/shibboleth/shibd.logger` -- configuration for log rotation, should come already set up out of the box


InCommon metadata setup
-----------------------

Use InCommon's Federation Manager to create or edit the metadata entry for the Service Provider.

- Copy most settings from the [sample metadata file](sample-SP-metadata.xml)
- Only give InCommon the public key (sp-cert.pem), not private!
- The key generated above uses AES-128-CBC encryption



Testing
----------

These commands will test various aspects of the Shibboleth service (replace "sandbox" with the specific DNS name):
- Is the shibboleth2.xml valid?
  - `shibd -t`
- Details of the certificate:
  - `openssl x509 -text -noout -in /etc/shibboleth/sp-cert.pem`
- Is shibboleth responding through Apache?
  - `curl -k https://localhost/Shibboleth.sso/Status`
- What metadata is InCommon delivering for this SP?
  - `mdquery -e https://sandbox.datadryad.org`
  - `curl https://sandbox.datadryad.org/Shibboleth.sso/Metadata`
- Does the end-to-end shibboleth traffic work?
  - (in browser) https://sandbox.datadryad.org/cgi-bin/PrintShibInfo.pl
  - (in browser, after a session is established) https://sandbox.datadryad.org/Shibboleth.sso/Session
- See logs in `/var/log/shibboleth`
  - shibd.log and shibd_warn.log show issues with shibd itself
  - transaction.log shows details of the communication with InCommon


Troubleshooting
-----------------

If Shibboleth doesn't start properly, a non-compatible Shibboleth from the OS
may be getting in the way. In this case, find the "extra" shibd.service file and
rename it before starting the service:

```
sudo systemctl disable shibd.service
cd /etc/systemd/system sudo
mv shibd.service shibd-old.service
sudo systemctl enable shibd.service
```

Renewing certificates for Shibboleth
===================================

See renewal instructions in the [AWS EC2 documentation](../external_services/amazon_aws_ec2_setup.md)

