ActiveJob / Delayed Job
=========================

The Rails framework ActiveJob libraries are meant to address these
issues and are a common standard way to address background processing
for a Rails application.  ActiveJob works as a wrapper around the most
popular backends for asynchronous queuing and processing that are most
commonly mentioned: Sidekiq, Resque and (Shopify's) Delayed Job.  If
using the ActiveJob interface, the backend can be switched out with
only a bit of configuration change if more scaling is needed.

Delayed Job is attractive since it saves its queue in a table in the
application's MySQL database and doesn't require another server
technology (Redis) to be installed and managed.  It also doesn't
involve extra worry for saving queue state like the technologies that
rely on Redis which is an in-memory store and may not save the queue
in the case of an irregular exit or crash.

The Redis-backed asyncronous queuing systems apparently are very fast
and can handlea huge numbers of queuing requests with ease, but I
believe are all overkill for the few dozens to hundreds or even few
thousands of queueing jobs we'll likely do every day (this scale is
very small compared to how some people use these systems).

Delayed Job saves queue state to the database (from request by
ActiveJob) and a separate independent Delayed Job daemon process picks
up jobs off the queue and processes them so they run independently of
the web server processes.  The items enqueued can be of all different
types and it can contain multiple different named queues for jobs (as
well as priorities, time scheduling and other features).  While the
application code needs to be present, the Delayed Job queue processor
could run on any server that has access to the database and doesn't
even need to run on a UI server and probably wouldn't use most of the
application code.

I've made a PR with the configuration and a simple example of using
the queue to write to a file text to a file to see how things happen.

Some notes & common commands to manually try out delayed job/ActiveJob
on this branch.

```
https://github.com/collectiveidea/delayed_job
https://axiomq.com/blog/deal-with-long-running-rails-tasks-with-delayed-job/
https://github.com/collectiveidea/delayed_job/issues/776
https://github.com/collectiveidea/delayed_job/wiki/Delayed-job-command-details
https://guides.rubyonrails.org/v4.2/active_job_basics.html


RAILS_ENV=local_dev bin/delayed_job start
RAILS_ENV=local_dev bin/delayed_job stop
-n, --number_of_workers=workers

StashEngine::ZenodoCopyJob.perform_later('my cat has fleas')
StashEngine::ZenodoCopyJob.perform_later('my dog has fleas')
StashEngine::ZenodoCopyJob.perform_later('my rat has fleas')
```

We will need to add additional states and other thing to our database
for tracking since ActiveJob is really just a work queue and doesn't
automatically track application states.

We really may want to move our Merritt submissions to use something
like this rather than the expansion I made to David's home-baked
queueing system which still runs inside the UI server processes and
can have problems if the UI server goes down at a bad time.
