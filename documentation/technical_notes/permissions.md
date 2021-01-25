
Permissions in Dryad
====================

Dryad has several levels of permissions. Some permissions are defined by the
`User.role` field:
- *superuser* -- Has full access to all features in the system
- *tenant_curator* -- Has view and edit access to all datasets in the associated
  tenant
- *admin* -- Has view access to all datasets in the associated tenant,
  regardless of publication status.
- *user* -- Has view access to published datasets. Has view and edit access to
  datasets they created.

Other permissions are orthogonal to the `User.role`:
- *journal_admin* -- Has view and edit access to all datasets associated with an
   article in the appropriate journal. Journal administrators are defined by
  `User.journal_role`, so they may overlap or overried permissions defined by
  `User.role`. 
- *API access* -- All users are able to use the public API without authentication. However,
  some portions of the API require authication. Once a user is
  authenticated through the API, their other permissions take
  effect. To allow a user access to the API, see [Adding API Accounts](../apis/adding_api_accounts.md).

