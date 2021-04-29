
Status Dashboard
==================

The status dashboard is only viewable to superusers.

For each service shown on the dashboard, information is stored in three places:
- objects in the database `stash_engine_external_dependencies`
- service classes in `stash/stash_engine/app/services/stash_engine/status_dashboard/`
- database initialization description in `stash/stash_engine/lib/tasks/status_dashboard.rake`

To add/remove items in the dashboard, you must edit all of the items listed above!

Every 5 minutes, a cron job runs to verify that the parts of the system are
running. The cron job:
- selects ExternalDependency items
- for each item, runs the associated service class
- updates the status and error message in the database table

The `status_dashboard` simply displays the corresponding information from the database.
