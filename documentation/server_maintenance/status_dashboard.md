

Status Dashboard
==================

The status dashboard allows monitoring of the various services that
are required for Dryad to run, both internal and external. The status dashboard
is only viewable to superusers.

To add a new checker:
- add a checker to `stash/stash_engine/app/services/stash_engine/status_dashboard/`
- add an entry to `stash/stash_engine/lib/tasks/status_dashboard.rake`
- on any server where the checker needs to run, re-seed the database
  with the list of checkers: `rails status_dashboard:seed`
  (database entries are stored in `stash_engine_external_dependencies`)

To remove items from the dashboard, you must edit all of the items listed above!

To run a checker in the Rails console, both instantiate it and specify its
abbreviation:
```
dc=StashEngine::StatusDashboard::DBBackupService.new(abbreviation: 'db_backup')
dc.ping_dependency
```

On a normal Dryad server, a cron job runs `bundle exec rails status_dashboard:check` to
verify that the parts of the system are running. The checking process:
- selects ExternalDependency items
- for each item, runs the associated service class
- updates the status and error message in the database table

The `status_dashboard` web page simply displays the corresponding information from the database.
