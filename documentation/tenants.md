Tenants
========

A "tenant" in Dryad is an organization that is associated with some
subset of users. Typically, the tenant is a university, and all users
at that university can associate their accounts with the tenant to
gain special features, like prepaid deposit fees.

Adding a New Tenant
====================

Tasks:
- In the `config/tenants` directory, add a config file for the tenant
- In the `app/assets/images/tenants` directory, add a logo
- After the new configuration goes live, in the production database,
  update `tenant_id` for all entries in `stash_engine_users` who have emails with the
  institutional domain name 

Prerequisites and Dependencies for a New Tenant
------------------------------------------------

You’ll need these things configured before you can get a
fully-functioning install for a tenant.  Many of these will require
you to get separate instances of items for each dev, stage and
production deployment you’d like to activate.

For UC tenants only:
- A EZID or DataCite account and configuration for generating
  identifiers and submitting metadata to them. (We’re using fake demo
  shoulders for most of dev/stage/demo.)
- A Merritt account with login information for submitting and storing
  the content (may need multiple for dev/stage/prod)
- A configured external login method via Shibboleth
- Logo
- Campus contacts

Adding the Configuration
-------------------------

The easiest way to configure an instance is to copy the configuration
from another and then modify the values. Since the UC campuses have
somewhat different settings than other institutions, it is best to
copy from an institution of the same type (UC or non-UC).  The
configurations set a default configuration and then override the
defaults for development, stage, demo and production environments
since many of the configs remain the same for all environments.

If you override a specific configuration key that has sub-values, be
sure to put in all sub-values.  When the parent key is overridden, any
sub-values are no longer present so you’ll need to re-enter all
sub-values for a key if you override it (for nested elements).

Some configuration option information:

`enabled`: true or false.  If false then that tenant will not show up or
allow log in.

`repository` is always Merritt right now.  The main options are domain,
endpoint url for sword, username and password used for http basic auth

`abbreviation`, `short_name`, `long_name`: different versions of an
institution name like UCLA; UC Los Angeles; University of California,
Los Angeles.  The `abbreviation` must be unique. The `short_name` should
be the most commonly used form of the name --  is the one that is used
for users to choose when they log in, and for setting values for
dataset publisher.

`publisher_id` is the GRID ID -- you can get it from the ROR database

`ror_id` -- can likewise come from ROR. All entries in this list will
show up when tenant administrators view "their" content on the admin page.

`tenant_id` should be a unique value for the tenants you have installed
and should not be changed later. It is useful to have this be the same
as the short_name, but all lowercase. Also useful to have this the
same as the name of the config file.

`identifier_service` is always EZID for UC tenants, and DataCite for
everyone else.  There are sub-keys for shoulder, account, password,
id_scheme (always doi right now).

authentication:
- `authentication_strategy` is usually shibboleth right now.  There are
  other keys and values under authentication depending on the strategy
  chosen.
  - `entity_id`
    - Seems that if you go to https://dryad-stg.cdlib.org/cgi-bin/printenv and
      search for the item in the list while having your browser inspector open
      to the network tab you may be able to dig out the entity id.  I found mine
      in the response for the file "DiscoFeed" where it had some JSON with the
      display name I selected and the entityID.  But seems like it only allows
      discovery for some institutions.
    - (old way) can normally be found by looking up the institution’s from
       the InCommon config file. On stage/prod, this is
       `/apps/dryad/local/shibboleth-sp/var/InCommon-metadata.xml`. If the
    institution is not part of InCommon, the shibboleth for that
    institution may be configured separately. Look at the files in prod
    directory `/apps/dryad/local/shibboleth-sp/etc/shibboleth`.
    
  - `entity_domain` is simply the domain portion of the entity_id
- A strategy of `author_match` allows login by that institution without
  shibboleth validation, but requires an author to be from the same tenant
  (an author ROR institution should match).
- A strategy of `ip_address` allows validating membership by requiring that
  the user logs in from their organization network the first time.  The organization
  supplies the network ranges that are allowed and we put in an array under the
  key `ranges`.  The format is those accepted by ipaddr.rb which could be in
  CIDR (ie "192.168.1.0/24") or network mask formats like "192.168.1.0/255.255.255.0"
  (see their docs).  It also supports IPv6 (which we're not currently using).

`default_license` is either cc0 or cc_by right now but might be set to
other licenses configured at the application-level with some text and
a logo.

`campus_contacts` is the list of email addresses that will be copied on
each submission to this tenant.

`usage_disclaimer` is text that is displayed on top of the review page
before submitting a dataset. Can be left out or left blank, but UC
Press wanted this disclaimer when people go to submit.

`covers_dpc` is typically true, since covering the DPC is the main
reason institutions become tenants.


Adding the logo and institution to the list
-------------------------------------------

Logos go into `app/assets/images/tenants`

Add the institution to the list in `app/views/layouts/_members_institutional.html.md`


Updating pre-existing users in the database
-------------------------------------------

*Only do this after a tenant has gone live on the production server.*

Existing users in the database will want to take advantage of the new
tenant status. To do this, determine the email suffix that applies to
users of the tenant, and update them with a command like:

`update stash_engine_users set tenant_id='columbia' where email like '%columbia.edu';`

Testing the setup
-------------------

Deploy the setup to a non-production server. (Best to test this from
our stage server.)

In the database for that server, remove the `tenant_id` for the user you
will be testing with.

Go to login, and you should see the selection screen for shibboleth.

Select the new tenant, and verify that it goes to their shibboleth
login screen.

You won't be able to login at their site, so go back to the DB and
manually set your tenant to the target tenant.

Go to the user dashboard and make sure the logo shows up.

