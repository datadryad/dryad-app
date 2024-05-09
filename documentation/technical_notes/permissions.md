
Permissions in Dryad
====================

All users have view access to published datasets, as well as view and edit access to
datasets they created.

## Roles table

Dryad has several levels of permissions. Permissions are defined in `StashEngine::Role`.
The easiest way to handle user permissions is in the user management UI.

In the table or rails console, system users have no role_object. The permissions levels
of system users are:
- *superuser* -- Has full access to all features in the system. Superusers
  automatically have permissions to do anything that any other type of user can do.
- *curator* -- Has access to most features, though not some that are more
  dangerous and only useful to developers.
- *admin* -- Has view access to most features and datasets.

Additionally, roles can be created with a role object of type `StashEngine::Tenant`,
`StashEngine::Journal`, `StashEngine::JournalOrganization`, or `StashEngine::Funder`.
For these associated organizations, the permissions levels are:

- *curator* -- Has view and edit access to all datasets associated with the role object
- *admin* -- Has view access to all datasets associated with the role object

## API access

All users are able to use the public API without authentication. However, some portions
of the API require authentication. Once a user is authenticated through the API, their other
permissions take effect. To allow a user access to the API, see [Adding API Accounts](../apis/adding_api_accounts.md).
