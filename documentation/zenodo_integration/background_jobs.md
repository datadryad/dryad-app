# Zenodo extra copies and software/supplemental submissions

See also the [troubleshooting document](zenodo_troubleshooting.md).

For environments that send datasets to Zenodo, the process of
transferring the data only lives on one server (e.g., 01, but not 02).


## ActiveJob / Sidekiq Background Jobs

The Rails framework ActiveJob libraries are meant to be a common standard
way to address background processing
for a Rails application. ActiveJob works as a wrapper around the most
popular backends for asynchronous queuing and processing that are most
commonly mentioned: Sidekiq, Resque and (Shopify's) Delayed Job. If
using the ActiveJob interface, the backend can be switched out with
only a bit of configuration change if more scaling is needed.

Sidekiq saves its queue in a Redis cache AWS instance.
The items enqueued can be of different types and can contain multiple different named queues for jobs 
(as well as priorities, time scheduling and other features).

```
https://github.com/sidekiq/sidekiq


# to start and stop locally
RAILS_ENV=development sidekiq
```

ActiveJob is really just a work queue and doesn't automatically track application states.

