External Services
===================

Notes and cheet sheets for services that are used by Dryad developers.


Status Dashboard
----------------

The status of both internal and external services are monitored
through the Status Dashboard. The primary monitoring process runs
through the rake task `status_dashboard:check`, which calls the
service-checking code in `stash/stash_engine/app/services/stash_engine/status_dashboard/`
