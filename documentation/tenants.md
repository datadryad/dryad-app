Tenants
========

A "tenant" in Dryad is an organization that is associated with some
subset of users. Typically, the tenant is a university, and all users
at that university can associate their accounts with the tenant to
gain special features, like prepaid deposit fees.

Adding a New Tenant
====================

Tasks:
- In the `dryad-config` repo, add a config file for the tenant
- In the `dryad-app` repo, add a logo
- After the new configuration goes live, in the production database,
  update `tenant_id` for all entries in `stash_engine_users` who have emails with the
  institutional domain name 
