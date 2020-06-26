Troubleshooting
==================

Some common problems and how to deal with them.

Also see the notes on
[handling failed submissions](https://confluence.ucop.edu/display/Stash/Dryad+Operations#DryadOperations-FixingaFailedSubmission).

Interactions with Merritt
===========================

Submissions to Merritt can be started and stopped from the
[GUI Submission Queue page](https://datadryad.org/stash/submission_queue). However,
actions on this page will only affect the single server that you are
attached to, and not all servers in a load-balanced system.

Stopping Merritt Submissions
-----------------------------

To pause Merritt submissions, on each server:
```
touch apps/ui/releases/hold-submissions.txt
```

(Re)Starting Merritt Submissions
-----------------------------

To restart Merrit submissions, on each server:
```
rm apps/ui/releases/hold-submissions.txt
```

THEN, on one server, in the Rails console:
```
resource_ids =
StashEngine::RepoQueueState.latest_per_resource.where(state:
'rejected_shutting_down').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
StashEngine.repository.submit(resource_id: res_id)
end
```


Merrit async download check
----------------------------

This error typically means that the account being used by the Dryad UI
to access Merritt does not have permisisons for the object being
requested. This is often because either the Dryad UI or the object in
Merritt is using a UC-based account, while the other is using a non-UC account.


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
RAILS_ENV=production bundle exec rake rsolr:reindex
```

Forcing a dataset to submit
============================

Sometimes a dataset becomes "stuck in progress". This is often due to
confusion on the part of a user, but there are times when the user
loses access to editing a particular version of a dataset. Find the
most recent resource object associated with that dataset, and force it
to submit:

```
StashEngine.repository.submit(resource_id: <resource_id>)
```

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
===========================

Occasionally, there will be a problem sending metadata to DataCite for
an item. You can force the metadata in DataCite to update by:

```
idg = Stash::Doi::IdGen.make_instance(resource: r)
idg.update_identifier_metadata!
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
	  
