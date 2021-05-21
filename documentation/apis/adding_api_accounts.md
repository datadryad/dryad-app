Adding a New API Account
========================

Each API account must be associated with a user account. In most
cases, the user requesting the account will have previously logged in to
Dryad so they have a user record and you will want to find their user
record in the database.

In special cases where the API account will not be attached to a
single person, we must still create a new user account. This can be
created (e.g. in Rails console) without a specific ORCID, but ensure
it does have a valid email address so it can receive notifications
about the datasets. Ensure the people who will access the API account
users understand that they will still need "normal" ORCID-based
accounts to access the Dryad web interface.

To create an API account:
1. Log into Dryad with a user that has the superuser role (set the
   role of your user record to 'superuser' if you need to). Go to the
   path `/oauth/applications` on the server and add a new application.
2. Fill in an application name and a redirect uri.  The redirect URI
   isn't used for this case, but it forces a fill-in, anyway.
3. Figure out the user id in our database for the user who will access
   the API, also have the application id for this newly-created
   application for the next steps (it is shown as an ID in the URL when
   you're viewing that application information).
4. In the database, update the `oauth_applications` table to
   relate the user with the application:
   `update oauth_applications set owner_type = 'StashEngine::User', owner_id = <user id> where id = <application id>;`
5. Verify that the associated user account has a `tenant_id` set. If it is null,
   set it to `dryad`.
   `select * from stash_engine_users where id= <user id>;`

To set permissions for the API account:
- The user can be set to a `superuser` or tenant-based `admin` role using
  either the database or rails console:
  `update stash_engine_users set role='admin' where id= <user id>;`
  `StashEngine::User.find(<user id>).update(role: 'admin')`
- The user can be set as a journal administrator using either the database or rails console:
  `insert into stash_engine_journal_roles (journal_id, user_id, role) values (1, 3, 'admin');`
  `StashEngine::JournalRole.new(user:u, journal:j, role:'admin').save`
