Troubleshooting and Maintenance
===============================

Some common problems and how to deal with them.

Also see the notes on [Interactions with Merritt](merritt.md)


Setting a maintenance notice on the site
========================================

If there is a serious issue that users need to know about, edit the file
`app/views/layouts/stash_engine/application.html.erb`

Add an alert box like this:
```
<div class="js-alert c-alert--informational" role="alert">
  <div class="c-alert__text">
    The message goes here!
  </div>
</div>       
```

In an emergency, you can make this edit on the production servers and restart
puma on each server, to avoid doing a full redeploy.


Dataset is not showing up in searches
===================================

If a dataset does not appear in search results, it probably needs to be
reindexed in SOLR. In a rails console, obtain a copy of the object and
force it to index:

```
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
solr = RSolr.connect url: Blacklight.connection_config[:url]
solr.delete_by_query("uuid:*")
exit

# in the bash shell again, subsitute the correct environment for <env>
RAILS_ENV=<env> bundle exec rails rsolr:reindex
```

Dataset submission issues
=========================


Forcing a dataset to submit
---------------------------

Sometimes a dataset becomes "stuck in progress". This is often due to
confusion on the part of a user, but there are times when the user
loses access to editing a particular version of a dataset. Find the
most recent resource object associated with that dataset, and force it
to submit:

```
StashEngine.repository.submit(resource_id: <resource_id>)
```

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

Check that the Merritt submission status daemon is running.

Be sure we can get results for queries from Merritt.

The daemon can be run manually with rake task like:
```
RAILS_ENV=<environment> bundle exec rails merritt_status:update
```

However, it will start automatically from systemd startup and
can be managed through it as the preferred method.


If the user needs to change a data problem that caused a submission error (rare)
--------------------------------------------------------------------------------

1. Set the stash_engine_resource_state to `in_progress`.
2. Ask them to edit and re-submit.

Changing the latest queue state doesn't matter since it will enqueue
when it's submitted by them again.

#We need a corporate author instead of an accountable individual author

In rare cases, we've allowed this, though, rarely.  Have a user submit the dataset like normal and when it is time
to change to a corporate author, do the following:

- Find the author in the `stash_engine_authors` table for the dataset.
  - Remove first name
  - Change last name to the corporate author
  - Change or fill the desired email
  - Remove the ORCID from the record
- Most will likely want the affiliation gone, also.  Remove the linking record in `dcs_affiliations_authors`
- Check the landing page to be sure it appears correctly.
- There may be additional things someone wants done such as waiving payment or other things.

Transfer Ownership / Change "Corresponding Author"
==================================================

The curators should give the dataset and ORCID information for who ownership goes to.  If you
discover that this user has never logged in then you cannot transfer ownership until
that user has logged in and has a record in the users table.

Look up the dataset to see what you're dealing with and the resources involved.

```
SELECT res.* FROM stash_engine_resources res
JOIN stash_engine_identifiers ids
ON res.identifier_id = ids.id
WHERE ids.identifier = '<bare-doi>'
```

Make a note of the user_id that owns the dataset and also note the last couple of resource.ids.

Lookup the desired user_id to transfer ownership to.  Curator should've given the ORCID.  Note their user.id.
```
SELECT * FROM `stash_engine_users` WHERE `orcid` = '<new-owner-orcid>';
```

Lookup the current user_id and note the ORCID, name (you already have their user.id).
```
SELECT * FROM `stash_engine_users` WHERE `id` = '<old-owner-id>'
```

Update both the user_id and current_editor_id for the last couple versions to match the new owner.
```
UPDATE stash_engine_resources SET user_id=<new-id>, current_editor_id=<new-id> WHERE id IN (<id1, id2>);
```

Often, a user or curator has completely destroyed the correct association between the
author and their ORCID by retyping someone else's name for the author that
had a verified ORCID.  Check to see.

```
SELECT * FROM `stash_engine_authors` WHERE `resource_id` IN (<id1, id2>);
```

If necessary, change the two authors so they have the same
ORCIDs associated with the names as in the user accounts 
(which will have names and ORCIDS correct).

If you don't update the authors to be sure authors/orcids are correct then the
"corresponding author" may not appear correctly and it also plays havok with data consistency
with ORCIDs for wrong people.


Setting embargo on a dataset that was accidentally published
=============================================================

First, go to the UI and add a curation note about manually embargoing
it; don't worry about the actual status, you'll change it in the DB.

In the database, run these commands, filling in the appropriate
identifiers at the end of each line, and the appropriate embargo date:
```
select id,identifier,pub_state from stash_engine_identifiers where identifier like '%';
select id, file_view, meta_view from stash_engine_resources where identifier_id=;
select * from stash_engine_curation_activities where resource_id=;
update stash_engine_curation_activities set status='embargoed' where id=;
update stash_engine_resources set file_view=false where identifier_id=;
update stash_engine_resources set publication_date='2020-07-25 01:01:01' where id=;
update stash_engine_identifiers set pub_state='embargoed' where id=;
```

Now run a command like the one one below if it has been published to Zenodo.  It will
re-open the published record, set embargo and publish it again with the
embargo date.  You can find the deposition_id in the stash_engine_zenodo_copies
table. The zenodo_copy_id is the id from that same table.
```
# the arguments are 1) resource_id, 2) deposition_id at zenodo, 3) date, 4) zenodo_copy_id
RAILS_ENV=production bundle exec rake dev_ops:embargo_zenodo 97683 4407065 2021-12-31 12342
```

Setting "Private For Peer Review" (PPR) on dataset that was accidentally published
==================================================================================
```
select id,identifier,pub_state from stash_engine_identifiers where identifier like '%';
select id, file_view, meta_view from stash_engine_resources where identifier_id=;
select * from stash_engine_curation_activities where resource_id=;
update stash_engine_curation_activities set status='submitted' where id=;
update stash_engine_resources set file_view=false, meta_view=false, solr_indexed=false where identifier_id=;
update stash_engine_resources set peer_review_end_date='2023-07-25', publication_date=NULL where id=;
update stash_engine_identifiers set pub_state='unpublished' where id=;
INSERT INTO `stash_engine_curation_activities` (`status`, `user_id`, `note`, `keywords`, `created_at`, `updated_at`, `resource_id`)
  VALUES ('peer_review', '0', 'Set to peer review at curator request', NULL, '2022-07-27', '2022-07-27', 
  <resource-id>);

select * from stash_engine_zenodo_copies where resource_id=;
```

Now run a command like the one one below if it has been published to Zenodo.  It will
re-open the published record, set embargo and publish it again with the
embargo date.  You can find the deposition_id in the stash_engine_zenodo_copies
table. The zenodo_copy_id is the id from that same table.
```
# the arguments are 1) resource_id, 2) deposition_id at zenodo, 3) date, 4) zenodo_copy_id
RAILS_ENV=production bundle exec rake dev_ops:embargo_zenodo 97683 4407065 2023-07-25 1234
```

Remove from our SOLR search:
```
bundle exec rails c -e production # console for production environment
solr = RSolr.connect url: Blacklight.connection_config[:url]
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
- (if it's EZID, you may have to do this a different way, but most are datacite dois)


Permanently removing data that was accidentally published (and should never be)
===============================================================================

Delete Dataset / Removing an entire dataset
--------------------------

Dataset removal should not be taken lightly. Make sure you "really" need to
remove it, due to highly sensitive data and/or serious copyright issues.

If it was published to zenodo, you may want to embargo it all for a long time until
Alex can remove if it is time-critical.  Do it before deleting it everywhere else since
it is harder to do after removal.

```
# the parameters are 1) resource_id, 2) deposition_id (see in stash_engine_zenodo_copies), 3) date far in the future
RAILS_ENV=production bundle exec rails dev_ops:embargo_zenodo <resource-id> <deposition-id> 2200-12-31
```


If you need to completely remove a dataset from existence, you can run
```
rails dev_ops:destroy_dataset 10.27837/dryad.catfood
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
  Merritt/Zenodo. You will need to manually request that these versions be
  removed. 
  -  What needs to happen in Merritt is documented at
     [Removing older versions of a Dash/Dryad dataset object in Merritt](https://confluence.ucop.edu/pages/viewpage.action?pageId=221218281)
- Merritt may give us a new ARK for the new dataset.  We will edit the
  `stash_engine_resource.download_url` to contain the new ARK, encoded for the new
  dataset.
- For any resources that have been removed from Merritt, also remove them from Dryad
- For the remaining resources, go into the `stash_engine_generic_files` and edit
  the file uploads to match the files that are actually in Merritt.
  Essentially change any files that appear for the first time to a
  `file_state` of "created" and delete the rows for any files that have been removed.
- Go into `stash_engine_versions` and change the version and merritt_version to
  match the actual versions in Merritt. Check the downloads of both the full
  version and the individual files in the Dryad UI to be sure they still work.
  They should work if things were changed correctly.


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
an item. You can force the metadata in DataCite to update by:

```
idg = Stash::Doi::IdGen.make_instance(resource: r)
idg.update_identifier_metadata!
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

```
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

```
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
- Log into the AWS Console and examine the AWS Lambda function.  You can browse logs stored on amazon to see
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

