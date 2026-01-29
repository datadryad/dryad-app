Troubleshooting and Maintenance
===============================

Some common problems and how to deal with them.

Also see the notes on [Interactions with Merritt](merritt.md)


Setting a maintenance notice on the site
========================================

If there is a serious issue that users need to know about, edit the file
`app/views/layouts/stash_engine/application.html.erb`

Add an alert box like this:
```html
<div class="js-alert c-alert--informational" role="alert">
  <div class="c-alert__text">
    The message goes here!
  </div>
</div>       
```

In an emergency, you can make this edit on the production servers and restart
puma on each server, to avoid doing a full redeploy.


Restoring metadata from a database backup
=========================================

If the database is corrupted, it can be rebuilt from an AWS snapshot. But it is sometimes useful
to do a more targeted restore from one of our local backups (e.g., if someone runs a SQL command
with a typo and wipes out the values in a single column).

1. Extract the recovery SQL:
```
# from the backup file, extract only the table that you want to restore. This sed command will extract 'mytable':
$ sed -n -e '/CREATE TABLE.*`mytable`/,/Table structure for table/p' mysql.dump > mytable.dump
```
2. At the top of the new file, add a drop table command:
```sql
DROP TABLE IF EXISTS `mytable`;
```
3. In the new file, just above the table contents, remove any "commented" commands about character sets, like this:
```
/*!40101 SET @saved_cs_client     = @@character_set_client */;
```
4. Do the restore, setting the appropriate suffix to pick the password up from your config file:
```
mysql --defaults-group-suffix=stg --user dryaddba --host some-hostname dryad < queryfile.sql > output.txt
```


Dataset is not showing up in searches
===================================

If a dataset does not appear in search results, it probably needs to be
reindexed in SOLR. In a rails console, obtain a copy of the object and
force it to index:

```ruby
r=StashEngine::Resource.find(<resource_id>)
r.submit_to_solr
```

If many datasets need to be reindexed, it is often best to reindex the
entire system:
```
RAILS_ENV=production bundle exec rails rsolr:reindex
```

#Clean up and regenerate public search data

Take the following steps:

```ruby
# get a rails console in the *correct* environment
bundle exec rails console -e <env> # be sure you use development, stage or production here for <env>

# once in the console, clear out the existing (perhaps out of date or bad) records
solr = RSolr.connect url: APP_CONFIG.solr_url
solr.delete_by_query("uuid:*")
exit

# in the bash shell again, subsitute the correct environment for <env>
RAILS_ENV=<env> bundle exec rails rsolr:reindex
```

Dataset submission issues
=========================


Dealing with submission problems/resubmitting
---------------------------

Go to the `Submission queue` page, check the box and click `Resend checked submissions` if there is
a problem. If there is weirdness in the queuing and resubmitting you can look at `stash_engine_repo_queue_states`
and search by the resource_id. A normal submission goes through 'enqueued', 'processing', 
'provisional_complete' and 'complete'. `provisional_complete' means we got a success message from 
Merritt SWORD but we haven't seen it show up in Merritt as really completed yet and we wait to see
a real completion before taking actions since it may be delayed or rarely has a problem in Merritt.

If a submission has failed in Merritt, do the following on the server(s) to see Merritt error messages
to give to them or to troubleshoot the problem.

`less /home/ec2-user/deploy/current/log/production.log`

- Press `>` to go to the end of the file.
- Press CTRL-C to stop line number calculation.
- type `\Submission failed` which will search in a forward direction (you will not find it).
- type 'N' (must be a capital letter) to search backwards for the (N)ext of the same string, this should find the last 
  submission failures in the log.


Diagnosing a failed submission
------------------------------

Finding errors in the log is a pain. Open the application log with
something like `less`. Search for either the DOI or resource ID in
the log. Some good strings to search for:

`Submission failed for resource (number)` or `<doi>&lt` (replace the
number or the doi).

First determine what is going on with the failed submission
- What is the information for this resource in the stash_engine_submission_logs?
- What is the state for the resource in the stash_engine_resource_states (probably error)?
- What is the last state for this resource_id in the stash_engine_repo_queue_states?
- Does this resource have a download_uri and an update_uri in the stash_engine_resources table?

You might have to look through the UI logs to get detailed information
about an error. Focus on the approximate time in the logs when the
error happened.

You can access the Merritt interface directly or ask them about states
of an item.

If the resource has a download_uri and update_uri in
stash_engine_resources, it is most likely the payload has ingested
into Merritt and the error was caused by a timeout waiting for a
synchronous response from Merritt-Sword. This only applies to new
submissions. the URLs for version 2 and onward may have these URLs
copied from a previous submission.

Change the stash_engine_resource_state to `submitted` which indicates
a successful submission. Change the latest state for the resource in
stash_repo_queue_states to `completed` which will remove it from the
queue display. If the resource does not have a download_uri or
update_uri It is likely that there was an error during Merritt
processing. Look through the application log file for the DOI suffix
followed by an encoded less-than (&lt;). This will usually be part of
the encoded XML we received as part of the Merritt response. Decoding
the XML may give an indication about what went wrong. If not, send the
XML to the Merritt team and ask them what to do about the item.

See also: [Slides on Submission Processes](https://docs.google.com/presentation/d/11fcfEupLVTfh4EGuN9if3mBc3C2MBZSoTkngedBiBs8/edit?usp=sharing)

Errors in the queue_state or resource_state or stuck states
-----------------------------------------------------------

Check that the Sidekiq daemon is running.

The daemon can be restarted on the server like:
```
sudo systemctl restart sidekiq
# it can be run manually like `RAILS_ENV=<environment> bundle exec sidekiq' if needed
```

If the user needs to change a data problem that caused a submission error (rare)
--------------------------------------------------------------------------------

1. Set the stash_engine_resource_state to `in_progress`.
2. Ask them to edit and re-submit.

Changing the latest queue state doesn't matter since it will enqueue
when it's submitted by them again.

Transfer Ownership / Change "Corresponding Author"
==================================================

The curators should give the dataset and ORCID information for who ownership goes to. If you
discover that this user has never logged in then you cannot transfer ownership until
that user has logged in and has a record in the users table.

Look up the dataset to see what you're dealing with and the resources involved.

```ruby
StashEngine::Identifier.find_by(identifier: '<bare-doi>').resources
```

Note the last couple of resource.ids.

Lookup the current user and note the ORCID, name (you already have their user.id).
```ruby
StashEngine::Identifier.find_by(identifier: '<bare-doi>').resources.last.submitter
```

Lookup the desired user to transfer ownership to. Curator should've given the ORCID. Note their user.id.
```ruby
StashEngine::User.find_by(orcid: '<new-owner-orcid>');
```

Update both the submitter and current_editor_id for the last couple versions to match the new owner.
```ruby
StashEngine::Identifier.find_by(identifier: '<bare-doi>').resources.last.submitter = '<noted_user_id>'
StashEngine::Identifier.find_by(identifier: '<bare-doi>').resources.last(2).update(current_editor_id: '<noted_user_id>')
```

Often, a user or curator has completely destroyed the correct association between the
author and their ORCID by retyping someone else's name for the author that
had a verified ORCID. Check to see.

```ruby
StashEngine::Identifier.find_by(identifier: '<bare-doi>').resources.last.authors
```

If necessary, change the two authors `author_orcid` so they have the correct
ORCIDs, which should be those associated with the names as in the user accounts.
You should also check that the `author_email` for each author is correct.

If you don't update the authors to be sure authors/orcids are correct then the
"corresponding author" may not appear correctly and it also plays havok with data consistency
with ORCIDs for wrong people.

We need a corporate author instead of an accountable individual author
----------------------------------------------------------------------

In rare cases, we've allowed this, though, rarely. Have a user submit the dataset like normal and when it is time
to change to a corporate author, do the following:

- Find the author in the `stash_engine_authors` table for the dataset.
  - Remove first name
  - Change last name to the corporate author
  - Change or fill the desired email
  - Remove the ORCID from the record
- Most will likely want the affiliation gone, also. Remove the linking record in `dcs_affiliations_authors`
- Check the landing page to be sure it appears correctly.
- There may be additional things someone wants done such as waiving payment or other things.


Setting embargo on a dataset that was accidentally published
=============================================================

First, go to the UI and add a curation note about manually embargoing
it; don't worry about the actual status, you'll change it in the DB.

In the database, run these commands, filling in the appropriate
identifiers at the end of each line, and the appropriate embargo date:
```sql
select id,identifier,pub_state from stash_engine_identifiers where identifier like '%';
select id, file_view, meta_view from stash_engine_resources where identifier_id=;
select * from stash_engine_curation_activities where resource_id=;
update stash_engine_curation_activities set status='embargoed' where id=;
update stash_engine_resources set file_view=false where identifier_id=;
update stash_engine_resources set publication_date='2020-07-25 01:01:01' where id=;
update stash_engine_identifiers set pub_state='embargoed' where id=;
```

Removing a unpublished datasets and versions
============================================

Removing an unsubmitted (and unpublished) dataset
-------------------------------------------------

Datasets that are unsubmitted and unpublished will be removed by automatic
processes after the time is up. If you want to speed the process, you can find
the resource_id and simply destroy it in Rails console.


Removing an unpublished dataset
-------------------------------

Simply set the dataset to status `withdrawn`. The automatic cleanup processes will remove it after the time expires.


Removing an unpublished (most recent) version of a published dataset
--------------------------------------------------------------------

If there is a request to remove the latest version of a dataset, and that
version has not been published, you can find the resource_id and simply destroy
it in Rails console.


Other removal situations
------------------------

If you have a request to remove a version that is in the middle of the revision
history for a dataset, DON'T. This will mess up the revision chain, and data
files will not be correctly found. You can make this version invisible (`file_view=false` and/or `meta_view=false`).

For published datasets, see the sections below.


Setting "Private For Peer Review" (PPR) on dataset that was accidentally published
==================================================================================
```sql
select id,identifier,pub_state from stash_engine_identifiers where identifier like '%';
select id, file_view, meta_view from stash_engine_resources where identifier_id=;
select * from stash_engine_curation_activities where resource_id=;
update stash_engine_curation_activities set status='queued' where id=;
update stash_engine_resources set file_view=false, meta_view=false, solr_indexed=false where identifier_id=;
update stash_engine_resources set publication_date=NULL where id=;
update stash_engine_identifiers set pub_state='unpublished' where id=;
INSERT INTO `stash_engine_curation_activities` (`status`, `user_id`, `note`, `keywords`, `created_at`, `updated_at`, `resource_id`) VALUES ('peer_review', '0', 'Set to peer review at curator request', NULL, now(), now(), <resource-id>);

select id,state,deposition_id,resource_id, copy_type from stash_engine_zenodo_copies where identifier_id=;
```
For each finished `data`, `supp_publish` and `software_publish` record in the
`stash_engine_zenodo_copies` table do the following procedure. (see last query above)

Now run a command like the one one below for each of these published to Zenodo. It will
re-open the published record, set embargo and publish it again with the
embargo date. You can find the deposition_id in the stash_engine_zenodo_copies
table. The zenodo_copy_id is the `stash_engine_zenodo_copies.id` from that same table.


```
# the arguments are 1) resource_id, 2) deposition_id at zenodo, 3) date, 4) zenodo_copy_id
RAILS_ENV=production bundle exec rake dev_ops:embargo_zenodo -- --resource_id 97683 --deposition_id 4407065 --date 2023-07-25 --zenodo_copy_id 1234

```
**You must login to Zenodo and "publish" the new version of the dataset; otherwise the embargo
will not take effect. This is probably something we can fix in the code, but it is waiting for us
to revisit the Zenodo integration.**

Remove from our SOLR search:
```
bundle exec rails c -e production # console for production environment
```
```ruby
solr = RSolr.connect url: APP_CONFIG.solr_url
solr.delete_by_query("uuid:\"doi:<doi>\"")  # replace the <doi> in that string
solr.commit
exit
```

What to do at datacite?
- doi.datacite.org, login and search for doi under dois tab
- Click `update doi (form)`
- You cannot change this back to a draft now because it was published
- Under state, choose `Registered` instead of `Findable` and hopefully this is good enough since not a lot of other choices.
- Click `Update DOI`

# This dataset was accidentally published early (unpublish now and likely again published later)

See the instructions for "Private for peer review above" since it's almost the same process with a few minor
changes.

- In the step of setting "peer_review_end_date" set it to NULL instead.
- In the step of adding a curation_activity description, set to "curation" and
  "Set to unpublished at curator request" instead of the peer_review state.

We cannot easily remove everything from Zenodo or DataCite without a lot of problems and it sounds
like it will eventually get published again, anyway. For Zenodo, set the embargo an 
unreasonably long time into the future for the items that were published there. For Datacite change
to `Registered` instead of `Findable` so at least it's not searchable.

# A dataset has an extra file when downloading the zip vs the individual files

First check that Merritt and Dryad have the same number of versions. (Get the Merritt URL from
the resource.download_uri and change `/d/` to `/m/` in the url). If the number of versions is
different between the two systems it may be that the zip is downloading the wrong version
and it may need to be tweaked in the `stash_engine_versions` table (perhaps Merritt has an extra version).

Otherwise this sometimes happened when people changed filename case of a file that had been previously
uploaded to their dataset (shouldn't be a problem for these changes within the same version).

To fix the latest version of the dataset in Merritt, you'll need to do a manual reversion in a new
version to remove this file:

1. Find the dataset in the curation dashboard and begin editing it as a curator. Write down the resource_id (in url).
2. In the database set the `skip_emails` to `1` for the resource you're editing.
3. Open the `stash_engine_generic_files` table and find the last time the file existed for this dataset and
   duplicate the row.
4. Edit the newly duplicated row:
   - Change the `resource_id` to the resource_id from step 1.
   - Update the dates to something near the current date and time.
   - Change `file_state` to `deleted`.
   - Save changes.
5. Go to the last page of the submission form, enter a comment saying you're removing an extra published file
   from the Merritt versions and submit and wait for it to go through.
6. In `stash_engine_curation_activities` add an additional row at the end for the resource_id, setting
   the `status` to the previous version state (usually `published`), with your user_id and add a note like
   're-submitted to remove extra file'.
7. Assuming the previous version was the published one, go back to `stash_engine_resources` and
   set `meta_view` and `file_view` for the previous version to 0. Set those to 1 for the current
   version you just resubmitted. This will make this the new published version with the merritt files removed.


Permanently removing data that was accidentally published (and should never be)
===============================================================================

Delete Dataset / Removing an entire dataset
--------------------------

Dataset removal should not be taken lightly. Make sure you "really" need to
remove it, due to highly sensitive data and/or serious copyright issues.

If it was published to zenodo, you may want to embargo it all for a long time until
Alex can remove if it is time-critical. Do it before deleting it everywhere else since
it is harder to do after removal.

```
# the parameters are 1) resource_id, 2) deposition_id (see in stash_engine_zenodo_copies), 3) date far in the future
RAILS_ENV=production bundle exec rails dev_ops:embargo_zenodo -- --resource_id <resource-id> --deposition_id <deposition-id> --date <YYYY-MM-DD> --zenodo_copy_id <zenodo_copy_id>
```


If you need to completely remove a dataset from existence, you can run
```
rails dev_ops:destroy_dataset -- --doi 10.27837/dryad.catfood
```

This command will remove the dataset from Dryad, and give instructions to remove
it from associated services (e.g., Merritt and Zenodo).

It is possible to delete a dataset through the API, but only if you are using a
version of Dryad that includes the branch `migration-destroy-dataset`. You can
then make a `DELETE` call to `/api/datasets/<DOI>`.


Removing portions of a dataset
------------------------------

The explicit versions are set as ordinal numbers in Dryad and Merritt in the
`stash_engine_versions` table, but every version doesn't really need to exist
sequentially. The version number for Merritt needs to be set correctly to
download the files correctly from Merrit. They also do not need to be the same
ordinal numbers in each system (Merritt has a different version number than
Dryad in rare circumstances). These version numbers only display to
administrators, not normal users, so it is ok if they don't make complete sense.

To disappear a version non-destructively, but prevent access: in
`stash_engine_resources,` set `meta_view` and `file_view` to false(zero).

To actually remove a version and it is gone forever:
- Mark any offending versions as non-viewable, as described above. This prevents
  viewing/downloading the dataset while you are working on the subsequent steps.
-  Have the author submit the latest version of the dataset so it doesn't contain
  the problem items such as removing the sensitive files or making redacted
  versions of them and overwriting the old versions.
- Review the history of any offending files in the `stash_engine_generic_files`
  and identify which resources have files that need to be removed from
  Zenodo. You will need to manually request that these versions be
  removed. 
- For the remaining resources, go into the `stash_engine_generic_files` and edit
  the file uploads to match the files that are actually in Merritt.
  Essentially change any files that appear for the first time to a
  `file_state` of "created" and delete the rows for any files that have been removed.


Error message: Maybe you tried to change something you didn't have access to
============================================================================

This error message almost always means there was an error validating
an author.

The problem can be that an author's first or last name is blank,
OR it can be that an author's affiliation has a duplicate affiliation
in the DB. 


Error message:  Net::ReadTimeout
==================================

This timeout occurs when an external dependency is taking too long to
respond.

For "An ActionView::Template::Error occurred in resources#review",
check on the journal module. The review page in the submission system
may not be getting quick enough feedback.


Updating DataCite Metadata
==========================

Occasionally, there will be a problem sending metadata to DataCite for
an item. You can force the metadata in DataCite to update in the Rails console with:

```ruby
Stash::Doi::DataciteGen.new(resource: StashEngine::Resource.find(<resource_id>)).update_identifier_metadata!
```

Or select a set of resources and send it for each, for example:
```ruby
StashEngine::Resource.where('publication_date >= ?', 3.days.ago).each do |r|
  Stash::Doi::DataciteGen.new(resource: r).update_identifier_metadata!
end
```

To update anything published between a set of dates using a task, you can use:
```
RAILS_ENV=production bundle exec rails datacite_target:update_by_publication -- --start YYYY-MM-DD --end YYYY-MM-DD
```

If you need to update DataCite for *all* items in Dryad, you can use:
```
RAILS_ENV=production bundle exec rails datacite_target:update_dryad
```

There is a similar process for updating all items not in the main
Dryad tenant:
```
RAILS_ENV=production bundle exec rails datacite_target:update_dash
```

Fixing incorrect ROR affiliations
=================================

When a user has an affiliation that doesn't appear in ROR, but they
accidentally selected a ROR affiliation from the autocomplete box, the
UI won't allow them to change it. The UI assumes that we don't want to
replace a controlled value with an uncontrolled one.

To add the new (non-ROR) affiliation and associate it with the author,
follow a process like this:

```ruby
i=StashEngine::Identifier.where(identifier: '10.5061/dryad.z8w9ghx8g').first
r=i.resources.last
r.authors
# pick out the correct one and save it
a=r.authors.first
# create a new affiliation (append * to indicate it's not ROR-controlled)
a.affiliation=StashDatacite::Affiliation.create(long_name: 'Universidad Politécnica de Madrid*')
a.save
```

Fee Waivers and other Payments
==============================

If a user was charged (or is about to be charged) for a data deposit,
and the deposit should be waived or charged to another entity, change
the payment information recorded in the Identifier object. This allows us
to apply fee waivers or charge a different organization for the deposit.

```sql
update stash_engine_identifiers set payment_type="waiver", payment_id="<COUNTRY>" where id=<SOME_ID>;
```

Valid payment types and IDs are:
- payment_type = "waiver", payment_id = country with low-to-middle-income
- payment_type = "voucher", payment_id = voucher ID (should also set the voucher to "used" in the v1 database)
- payment_type = "institution", payment_id = tenant_id of 
- payment_type = "funder", payment_id = funder name
- payment_type = "journal-SUBSCRIPTION", payment_id = ISSN of sponsoring journal
- payment_type = "journal-DEFERRED", payment_id = ISSN of sponsoring journal

During normal processing, the payment information is only set at the
time a dataset is published. Once the payment information has been
set, the system will not change it.

If the dataset has already been published, and a payment has been
charged to the user, the payment_type will be `stripe`. In this case,
you can still change the payment_type to the desired value, but let
the curation team know that the associated Stripe invoice needs to be
voided.

Tabular data file isn't validating in Frictionless
==================================================
There could be a number of reasons for this, but there are a number of things to check to find where an error
might be happening.

- Check that the file has been uploaded correctly to S3 (check web browser console to see it completes and
  for any errors).
- The code should be polling an endpoint waiting for the report to appear in our database on the file upload
  page (you should also see this polling in the web browser javascript console)
- Log into the AWS Console and examine the AWS Lambda function. You can browse logs stored on amazon to see
  if there are any errors for recent runs of the Lambda function that validates.
- When the validation completes it will call a URL in our API to deposit the results of the validation
  which happens asynchronously in the background (this explains the polling a couple points above).
- Look at rails web server logs while you try to do the frictionless validation to see if any errors appear
  in the logs from the API method that updates the frictionless report.

For using in a development environment you will either need to use an environment that connects to our
standard development database (like `local_dev`) or create your own environment with configuration of
a domain name in the rails environment so that the callback can reach your instance's API to deposit results.

Issues with testing
=====================

Many failures with `latest_resource` and `current_status`
---------------------------------------------------------

This can be caused by the database triggers being dropped. To reinstantiate the
complete database setup:
`bin/rails db:migrate:reset RAILS_ENV=test`


Re-generating invoices for datasets
===================================

If you need to generate a new invoice for a dataset that has already been published:
1. On the Activity log page, look at the payment information to determine the current status of payment.
2. If there was a previous invoice, go into Stripe and ensure that it is voided.
3. In the database, remove the payment information from the dataset.
4. In a Rails console:
```ruby
r = StashEngine::Resource.find(<resource_id>)
user = StashEngine::User.find(r.current_editor_id)
inv = Stash::Payments::Invoicer.new(resource: r, curator: user)
inv.charge_user_via_invoice
```

Can't download a file because it is "not found"
================================================

For some old datasets, the Merritt system had trouble ingesting the
files. Some issues were manually corrected, and some issues were automatically
retried. For whatever reason, it is possible that Merritt's internal storage
tracking was slightly different than Dryad's storage tracking. This generally
didn't cause issues when we relied on Merritt to tell us the location of
files. Now that we construct the path information ourselves, the lookup can
sometimes fail when it runs into the old inconsistencies.

Possible problems with a file that won't retrieve from the old Merritt storage hierarchy:
- The resource where the file was created has the wrong `stash_version.merritt_version`
- The resource where the file was created has the wrong ARK, and other versions
  of the same dataset have different ARKs. (Don't worry about the details of
  ARKs. They just correspond to folder names in the `download_uri` for a resource)

To get some information about where Dryad thinks the file is stored:
```ruby
f = StashEngine::DataFile.find(<id>)
f = f.original_deposit_file
v = f.resource.stash_version.merritt_version
p = StashEngine::DataFile.mrt_bucket_path(file:f)
```

Look in the actual AWS S3 bucket, and see whether the file is stored in the ARK
and version indicated. You may need to adjust the `download_uri` and/or
`merritt_version` to sync up with the actual storage location.
