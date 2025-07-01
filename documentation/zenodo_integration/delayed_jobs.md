# Zenodo extra copies and software/supplemental submissions

See also the [troubleshooting document](zenodo_troubleshooting.md).

For environments that send datasets to Zenodo, the process of
transferring the data only lives on one server (e.g., 01, but not 02).


## ActiveJob / Delayed Job Background

The Rails framework ActiveJob libraries are meant to be a common standard
way to address background processing
for a Rails application. ActiveJob works as a wrapper around the most
popular backends for asynchronous queuing and processing that are most
commonly mentioned: Sidekiq, Resque and (Shopify's) Delayed Job. If
using the ActiveJob interface, the backend can be switched out with
only a bit of configuration change if more scaling is needed.

Delayed Job is attractive since it saves its queue in a table in the
application's MySQL database and doesn't require another server
technology (Redis) to be installed and managed.

Delayed Job saves queue state to the database (from request by
ActiveJob) and a separate independent Delayed Job daemon process picks
up jobs off the queue and processes them so they run independently of
the web server processes. The items enqueued can be of all different
types and it can contain multiple different named queues for jobs (as
well as priorities, time scheduling and other features). While the
application code needs to be present, the Delayed Job queue processor
could run on any server that has access to the database and doesn't
even need to run on a UI server and probably wouldn't use most of the
application code.

Some background info on delayed job

```
https://github.com/collectiveidea/delayed_job
https://axiomq.com/blog/deal-with-long-running-rails-tasks-with-delayed-job/
https://github.com/collectiveidea/delayed_job/issues/776
https://github.com/collectiveidea/delayed_job/wiki/Delayed-job-command-details
https://guides.rubyonrails.org/v4.2/active_job_basics.html

# to start and stop locally
RAILS_ENV=local_dev bin/delayed_job start
RAILS_ENV=local_dev bin/delayed_job stop
-n, --number_of_workers=workers
```

ActiveJob is really just a work queue and doesn't automatically track application states.

