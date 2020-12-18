Troubleshooting and Maintenance
===============================

Some common problems and how to deal with them.

Also see the notes on [Interactions with Merritt](merritt.md)

For information on deleting a dataset, see the (private) description
on the [Dryad Operations page](https://confluence.ucop.edu/display/Stash/Dryad+Operation).

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

If the download_uri and update_uri exist in the resource, then set it
to `complete` as above.

For an error state from Merritt that has been corrected (by fixing
Merritt or the dataset) and now the item needs to be sent to Merritt
again, see the [Merritt](merritt.md) docs to restart the submission.

If the latest stash_engine_repo_queue_state is stuck at processing (or
other states) or the resource_state is stuck at processing for an
unreasonably long time. An unreasonably long time is over 6
hours to a day depending on size of the submission and the queue.
See if Merritt received the submission, if they didn't receive it,
then treat it like an error state above and re-submit it (see above).
If Merritt has received and processed the submission and it's still
stuck, double-check that the OAI-PMH feed is working because if it
isn't then the we may never be notified something is complete.
Check that the completed item shows up in the OAI-PMH feed. (See
below.)

If the OAI-PMH feed is working and the item is present, check the
stash-notifier logs.  A pid file that was never removed may prevent
the notifier from processing additional items since it believes a
notifier instance is already running.  You may need to remove the pid
file or look to see if there is some problem with the notifier.  Maybe
a server got shut down in the middle of a run so the notifier didn't
have a chance to remove it's own pid.


If the user needs to change a data problem that caused a submission error (rare)
--------------------------------------------------------------------------------

1. Set the stash_engine_resource_state to `in_progress`.
2. Ask them to edit and re-submit.

Changing the latest queue state doesn't matter since it will enqueue
when it's submitted by them again.




Setting embargo on a Dataset that was accidentally published
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

Waiving Payments
================

If a user was charged (or is about to be charged) for a data deposit,
and the deposit should be waived or charged to another entity, change
the payment information recorded in the Identifier object.

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
