
I want to fix an individual failed Zenodo submission
=====================================================

1. Find all ZenodoCopies for this dataset: `select id,state,resource_id,copy_type from stash_engine_zenodo_copies where identifier_id=XXXXX order by resource_id;`
2. Save the above table in a text file (or ticket) so you can reference the needed IDs as you repair each resource.
3. Delete the errored rows: `delete from stash_engine_zenodo_copies where state='error' and identifier_id=XXXXXX;`
4. Starting with the first resource that had errored, resend each resource in
   order, and wait until each is completed before sending the next:
   `r.send_software_to_zenodo`
5. If the previous step failed for any resource, reference the email error or
   the error linked from the Zenodo submission queue page to determine what failed.
6. For entries with `copy_type=software_publish`, after the initial send, send again with `r.send_software_to_zenodo(publish: true)`


If a transfer fails due to Zenodo's inability to delete files, you can try:
1. Remove the appropriate "delete" entries from Dryad's `stash_engine_generic_files`
2. Run the `r.send_software_to_zenodo`
3. If it works, determine whether the Zenodo files are correct. You may need to
   manually delete the files that should have been deleted.


I want to go fix a number of failed Zenodo submissions. How?
=============================================================

Note: This process may not work if a particular Zenodo item is "stuck" in a way
that breaks the replication process. To fix a stuck item, use the above process.

1. Go to the *Datasets > Zenodo Submissions* option in the UI as a superuser.
2. ssh into the server and restart the Sidekiq process `sudo systemctl restart sidekiq` just to
   be sure old stuff is cleared out and it's running well.
3. Go back to the UI and click the *Reset stalled to error state* button. This will make items correctly
   show error states, even if they stalled or had another problem.
4. Sort the table by ID descending. Scroll down to about the time you saw the errors you want to correct starting.
5. Click the *Resend* buttons for items you care about (such as software or supplemental items, I'd ignore large data replications). Some items
   will need prerequisites to be submitted first (will show in the table after clicking).
6. Go up the list until you get to the top.
7. You can refresh the page to see current statuses. If you want to see a chain of items for an identifier then
   click on the *identifier id* and it will open a window with just submissions for that dataset. If you
   want to look at error and submission details then click on the zenodo_copies.id in the first column to troubleshoot.
8. Rinse and repeat steps 4-8 until all that you can fix is fixed. If you run into bad problems with useless
   crap clogging the queue then start at step 2 again.

You may have to read over error messages and see where things are failing in Zenodo and intervene with other
solutions manually.


Fixing "Please remove all files to create a new version in Zenodo" errors (workaround)
=======================================================================================

1. Find the previous submission where this was published (should be version before this one in
   `stash_engine_zenodo_copies` table). Write down or copy/paste the *old deposition_id* and save it.
2. Go into the Zenodo user interface on their site, find the item that won't go through and
   click the new version button. Write down the deposition_id for the *new deposition_id* (it should be
   in the URL). You can leave that page open in the UI if you wish.
3. Go to the zenodo_copies table and change the old deposition_id for the previously submitted version
   to the new item you just created in step 2. Also change the current submission's deposition_id to this number.
   (For some reason when it's in this state it's impossible to get the new deposits created through the API 
   until you do this.)
4. Resubmit through the Dryad queue interface for the item.
5. After it goes through, go back to the record from step 1 and put the *old deposition_id* back in as the correct one.


Fixing errors because of zero length files
==========================================

Zenodo has decided they do not accept zero length files in the API, which is suboptimal since there are a
number of cases in software when people add zero length files to indicate something (.gitkeep files come
to mind or Passenger web server lets you touch a file to change status). They may also indicate a file
to be filled or used later.

If you get errors because of Zero length files, our option is to go remove them all from our
`stash_engine_generic_files` table and resubmit the item. You may need to do this for multiple versions to
get them all through.


Can't upload anymore files to Zenodo?
======================================

Zenodo has now limited the number of files you can upload to 100 now. I suppose this means the user
must put them into a package like a zip if they want more files than that at Zenodo.


People put in dumb github URLs for software and the sizes don't match
=====================================================================

If they do this they should use the RAW URL from github, not just put in a github UI URL. They are not trying
to preserve the github UI for future generations. They want to get their software files in, not HTML
user interface files from github.
  

It's not processing? Why?
==========================

- Start or restart the Sidekiq service `sudo systemctl restart sidekiq` on the 01 server.
- There may be long (or stalled) jobs running on all workers. The Sidekiq UI table shows what is trying 
  to run in background.
- You can click the "reset stalled to error state" in the UI and it will put things no longer in the queue
  and with wrong statuses to "error" state and then you can resubmit the ones you want from the interface.

How to handle maintenance
=========================

- (On server 01) "pause" or "drain" the jobs a bit ahead with `touch ~/deploy/releases/defer_jobs.txt`.
  The Sidekiq process will not submit new things to zenodo while it's there
- After deploy, do `rm ~/deploy/releases/defer_jobs.txt`
- If you deployed new code you should restart the Sidekiq process. `sudo systemctl restart sidekiq`


How to clear out a big log jam of recently failed items
=======================================================

This sometimes happens because Zenodo is returning lots of 504 errors or has been down. At other times
there may be a lot of huge submissions that came in and are monopolizing all workers and they are spending
forever and timing out and nothing else can get through.

- Go to the *Admin > Zenodo Submissions* option in the UI and sort by ID descending. This should show you the
  items from most recent to least. The things that aren't recent probably aren't the current problem.
- Right now, submissions over 50GB rarely go in and Zenodo doesn't take items over this size in normal operations. 
  This will be a longer term thing to address, so go to the `stash_engine_zenodo_copies` table and set
  the retries column for the huge item(s) to `100` which will prevent it from coming back and being
  retried daily to try getting it in. Otherwise it'll just recreate the log jam tomorrow when it retries items.
- Restart the Sidekiq daemon `sudo systemctl restart sidekiq` on the 01 server.

Resending the stuff that failed (lets play the resubmisison game)
=================================================================

- You may need to remove the log jam (above) first.
- Go to *Admin > Zenodo Submissions* and sort as mentioned in the log jam section above. Sort by by ID, descending.
- Click the *Reset stalled to error state* button and the back button and refresh this page.
- Find about where the recent problems started. You want to try to get everything from there
  to the top of the list to resubmit, but probably ignore larger things in a first pass because you'll 
  have to wait forever for those to go through.
- Just clicking `resend` on everything in order up the list might not be optimal because items 
  for the same *ident.id* and type (software, data or supplemental) need to proceed in order and
  there are three workers so they may arrive out of order and give an error again.
- I prefer to click the *Ident.id* column for an item and open in a new tab. Then I can see if it's only one
  item or sort earlier items at the top or it's easy to follow what version needs to happen before another
  in a shorter list. I can resend the top one, refresh a few minutes later, resend the 2nd, etc.
- Alternately you can try clicking all the "resend" buttons up the list and some will error and you
  will get warnings about resending some and you can make multiple passes up the list and refreshes
  of the page until you get things through.
- If there are weird statuses that seem stuck you can always "reset stalled" and have another round or two of fun.


Manually reprocessing Zenodo software submissions
=================================================

Prepare the database
--------------------

Find all ZenodoCopies for this dataset:

`select id,state,resource_id,copy_type from stash_engine_zenodo_copies where identifier_id=142288 order by resource_id;`

Save the above table in a text file (or ticket) so you can reference the needed IDs

Delete the error rows:

`delete from stash_engine_zenodo_copies where state='error' and identifier_id='XXXXX';`

Reprocess resources in the Rails console
----------------------------------------

Starting with the first resource that had errored, resend each resource in order, and wait until each is completed before sending the next:
```
r=StashEngine::Resource.find(XXXXX)
r.send_software_to_zenodo
```

For entries with `copy_type=software_publish`, after the initial send, send again with `r.send_software_to_zenodo(publish: true)`
