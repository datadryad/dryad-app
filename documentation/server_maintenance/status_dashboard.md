
The status dashboard allows monitoring of the various services that
are required for Dryad to run, both internal and external.

To add a new checker:
- add a checker to `stash/stash_engine/app/services/stash_engine/status_dashboard/`
- add an entry to `stash/stash_engine/lib/tasks/status_dashboard.rake`

To run a checker manually, in the Rails console, both instantiate it
and specify its abbreviation:
```
dc=StashEngine::StatusDashboard::DBBackupService.new(abbreviation: 'db_backup')
dc.ping_dependency
```
