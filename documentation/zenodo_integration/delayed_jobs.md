# Zenodo extra copies and software/supplemental submissions

For environments that send datasets to Zenodo, the process of
transferring the data only lives on one server (e.g., 01, but not 02).

## I want to go fix a number of failed Zenodo submissions.  How?
1. Go to the *Datasets > Zenodo Submissions* option in the UI as a superuser.
2. ssh into the server and restart the delayed job daemon likw `sudo cdlsysctl restart delayed_job` just to
   be sure old stuff is cleared out and it's running well.
3. Go to the `delayed_jobs` table in the database and look for items that show `SIGTERM` or `Execution expired`
   I believe in the `last error` column but it may be another column.  Remove these records from the table.
4. Go back to the UI and click the *Reset stalled to error state* button.  This will make items correctly
   show error states, even if they stalled or had another problem.
5. Sort the table by ID descending. Scroll down to about the time you saw the errors you want to correct starting.
6. Click the *Resend* buttons for items you care about (such as software or supplemental items, I'd ignore large data replications).  Some items
   will need prerequisites to be submitted first (will show in the table after clicking).
7. Go up the list until you get to the top.
8. You can refresh the page to see current statuses. If you want to see a chain of items for an identifier then
   click on the *identifier id* and it will open a window with just submissions for that dataset.  If you
   want to look at error and submission details then click on the zenodo_copies.id in the first column to troubleshoot.
9. Rinse and repeat steps 4-8 until all that you can fix is fixed.  If you run into bad problems with useless
   crap clogging the queue then start at step 2 again.

You may have to read over error messages and see where things are failing in Zenodo and intervene with other
solutions manually.

## Fixing "Please remove all files to create a new version in Zenodo" errors (workaround)

This may be an error caused only by the transition, but I wouldn't be surprised if it reappears.

1. Find the previous submission where this was published (should be version before this one in
   `stash_engine_zenodo_copies` table).  Write down or copy/paste the *old deposition_id* and save it.
2. Go into the Zenodo user interface on their site, find the item that won't go through and
   click the new version button.  Write down the deposition_id for the *new deposition_id* (it should be
   in the URL). You can leave that page open in the UI if you wish.
3. Go to the zenodo_copies table and change the old deposition_id for the previously submitted version
   to the new item you just created in step 2. Also change the current submission's deposition_id to this number.
   (For some reason when it's in this state it's impossible to get the new deposits created through the API 
   until you do this.)
4. Resubmit through the Dryad queue interface for the item.
5. After it goes through, go back to the record from step 1 and put the *old deposition_id* back in as the correct one.

## Fixing errors because of zero length files

Zenodo has decided they do not accept zero length files in the API, which I think is a bad decision since there are a
number of cases in software when people add zero length files to indicate something (.gitkeep files come
to mind or Passenger web server lets you touch a file to change status). They may also indicate a file
to be filled or used later.

Anyway, if you get errors because of Zero length files, our option is to go remove them all from our
`stash_engine_generic_files` table and resubmit the item.  You may need to do this for multiple versions to
get them all through.

## Can't upload anymore files to Zenodo?

Zenodo has now limited the number of files you can upload to 100 now. I suppose this means the user
must put them into a package like a zip if they want more files than that at Zenodo.

## People put in dumb github URLs for software and the sizes don't match

If they do this they should use the RAW URL from github, not just put in a github UI URL. They are not trying
to preserve the github UI for future generations.  They want to get their software files in, not HTML
user interface files from github.
  
---

## It's not processing? Why?
- start or restart the service `sudo cdlsysctl restart delayed_job` on the 01 server.
- There may be long (or stalled) jobs running on all workers.  The `delayed_job` table shows what is trying 
  to run in delayed job.  If some of them have a `last_error` status like `execution expired` or `SIGTERM` then
  you can delete these lines out of the `delayed_job` table, restart the service and jobs stuck
  behind them should run.
- You can click the "reset stalled to error state" in the UI and it will put things no longer in the queue
  and with wrong statuses to "error" state and then you can resubmit the ones you want from the interface.

## How to handle maintenance
- (On server 01) "pause" or "drain" the jobs a bit ahead with `~/bin/long_jobs.sh drain`.  This just creates
  the file `defer_jobs.txt` in `deploy/releases` and it will not submit new things to zenodo while it's there.
- After deploy, do `~/bin/long_jobs.sh restart` or remove the `defer_jobs.txt` explained above. (The
  `hold-submissions.txt` file does something similar but for repository submissions).
- If you deployed new code you should restart delayed job.  `sudo cdlsysctl restart delayed_job`

## How to clear out a big log jam of recently failed items
This sometimes happens because Zenodo is returning lots of 504 errors or has been down.  At other times
there may be a lot of huge submissions that came in and are monopolizing all 3 workers and they are spending
forever and timing out and nothing else can get through.

- Go to the *Admin > Zenodo Submissions* option in the UI and sort by ID descending.  This should show you the
  items from most recent to least.  The things that aren't recent probably aren't the current problem.
- Right now, submissions over 50GB rarely go in and Zenodo doesn't take items over this size in normal operations. 
  This will be a longer term thing to address, so go to the `stash_engine_zenodo_copies` table and set
  the retries column for the huge item(s) to `100` which will prevent it from coming back and being
  retried daily to try getting it in.  Otherwise it'll just recreate the log jam tomorrow when it retries items.
- Restart the delayed_job daemon `sudo cdlsysctl restart delayed_job` on the 01 server.
- Remove the expired/Sigtermed items from the `delayed_jobs` table as explained in the "it's not processing"
  second point.

## Resending the stuff that failed (lets play the resubmisison game)
- You may need to remove the log jam (above) first.
- Go to *Admin > Zenodo Submissions* and sort as mentioned in the log jam section above.  Sort by by ID, descending.
- Click the *Reset stalled to error state* button and the back button and refresh this page.
- Find about where the recent problems started.  You want to try to get everything from there
  to the top of the list to resubmit, but probably ignore larger things in a first pass because you'll 
  have to wait forever for those to go through.
- Just clicking `resend` on everything in order up the list might not be optimal because items 
  for the same *ident.id* and type (software, data or supplemental) need to proceed in order and
  there are three workers so they may arrive out of order and give an error again.
- I prefer to click the *Ident.id* column for an item and open in a new tab. Then I can see if it's only one
  item or sort earlier items at the top or it's easy to follow what version needs to happen before another
  in a shorter list.  I can resend the top one, refresh a few minutes later, resend the 2nd, etc.
- Alternately you can try clicking all the "resend" buttons up the list and some will error and you
  will get warnings about resending some and you can make multiple passes up the list and refreshes
  of the page until you get things through.
- If there are weird statuses that seem stuck you can always "reset stalled" and have another round or two of fun.

## ActiveJob / Delayed Job Background

The Rails framework ActiveJob libraries are meant to be a common standard
way to address background processing
for a Rails application.  ActiveJob works as a wrapper around the most
popular backends for asynchronous queuing and processing that are most
commonly mentioned: Sidekiq, Resque and (Shopify's) Delayed Job.  If
using the ActiveJob interface, the backend can be switched out with
only a bit of configuration change if more scaling is needed.

Delayed Job is attractive since it saves its queue in a table in the
application's MySQL database and doesn't require another server
technology (Redis) to be installed and managed.

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

