Tenants
========

A "tenant" in Dryad is an organization that is associated with some
subset of users. Typically, the tenant is a university, and all users
at that university can associate their accounts with the tenant to
gain special features, like prepaid deposit fees.

Adding a New Tenant
====================

Tasks:
- In the `app/assets/images/tenants` directory, add the banner logo for the tenant
- Add the tenant's configuration information to the database
- After the new tenant is live in the production database,
  update `tenant_id` for all entries in `stash_engine_users` who have emails with the
  institutional domain name 

Prerequisites and Dependencies for a New Tenant
------------------------------------------------

You’ll need these things configured before a tenant will be
fully-functioning.

- Logo
- ROR ID(s)
- Agreement information
- A configured external login method via Shibboleth

Adding the logo
---------------

Logos go into `app/assets/images/tenants`

Adding the Configuration
-------------------------

Each entry in `StashEngine::Tenants` contains the following fields:
```ruby
tenant_hash = {
  id: '' , # tenant ID string, usually matching the tenant's domain. Required!
  short_name: '', # tenant name,
  long_name: '', # any alternate, longer tenant name, or duplicate of short_name
  authentication: {}.to_json, # a json object, for property options see below
  campus_contacts: [].to_json, # a json array
  payment_plan: nil, # an enum for different agreed payment plans, default is nil
  enabled: true, # whether the tenant is enabled to be claimed by users
  partner_display: true, # whether the tenant should appear on the member list
  covers_dpc: true, # whether the tenant will cover associated user datasets
  sponsor_id: nil, # for consortium members
}

# You can insert a new tenant in the database, or with the rails console:
StashEngine::Tenant.create!(tenant_hash)
```

After the tenant is created in the table, you must also add any associated
ROR IDs to `StashEngine::TenantRorOrgs`:
```ruby
# You can insert a new tenant in the database, or with the rails console:
StashEngine::TenantRorOrg.create!(tenant_id: <tenant_id>, ror_id: <ROR ID URL>)
```

### Field details

`id`: required and must be unique. If possible, this should match the tenant's web domain.

`short_name`, `long_name`: different versions of an institution name like "UC Los Angeles"
and "University of California, Los Angeles". The `short_name` should be the most commonly
used form of the name, and is seen most often by users. The `long_name` appears on the
partner display list.

`authentication`: an object containing a `strategy` and other information dependant on the strategy.
- `strategy`: the method by which users identify with the institution.
    - A strategy of `shibboleth` allows login using our [shibboleth][shibboleth/README.md] setup. As of 2025 we are only accepting shibboleth setups through InCommon. The following additional keys should be included in the object:
        - `entity_id` discoverable in https://incommon.org/community-organizations/
        - `entity_domain` is simply the domain portion of the entity_id
    - A strategy of `email` allows a code to be sent to an affiliated email. The user inputting this code authenticates the user.
        - `email_domain` should be included in the object. The user must receive email at an address at this domain.
    - A strategy of `author_match` allows login by that institution without login validation,
      but requires an author to list an affiliation from the same tenant (ROR ID must match).
    - A strategy of `ip_address` allows validating membership by requiring that
      the user logs in from their organization network the first time.
          - The organization supplies the network ranges that are allowed, and we include an array
          in the object under the key `ranges`. The format is those accepted by ipaddr.rb which
          could be in CIDR (ie "192.168.1.0/24") or network mask formats like "192.168.1.0/255.255.255.0"
          (see their docs). It also supports IPv6 (which we're not currently using).

`campus_contacts`: the list of email addresses that will be copied on
each submission to this tenant.

`payment_plan`: in indication for the type of payment plan agreed to by the tenant

`enabled`: true or false. If false then that tenant will not show up or allow log in.

`partner_display`: true or false. Whether the (enabled) tenant should be displayed on the member list. 

`covers_dpc`: true or false. If false then the member users will be asked to pay the DPC.

`sponsor_id`: for consortia, the tenant_id of the tenant with the consortium-level administrators

`ror_id`: the tenant representatives should provide a list of all ROR IDs associated with
their institution. Datasets affiliated with all entries will show up when tenant administrators 
view their admin pages.


Testing the shibboleth setup
----------------------------

1. Add the tenant details and deploy the logo to a non-production server. (Best to test this from
our sandbox.)
2. In the database for that server, remove the `tenant_id` for the user you
will be testing with.
3. Go to login, and you should see the selection screen for shibboleth.
4. Select the new tenant, and verify that it goes to their shibboleth
login screen.
5. You won't be able to login at their site, so go back to the DB and
manually set your tenant to the target tenant.
6. Go to the user dashboard and make sure the logo shows up.


Updating pre-existing users in the database
-------------------------------------------

*Only do this after a tenant has gone live on the production server.*

Existing users in the database will want to take advantage of the new
tenant status. To do this, determine the email suffix that applies to
users of the tenant, and update them like:

```ruby
StashEngine::User.where("email like '%columbia.edu'").update_all(tenant_id: 'columbia')
```
