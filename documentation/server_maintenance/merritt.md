Dryad–Merritt storage
=====================

Storage and replication for Dryad are managed by Merritt.  The primary
storage for Dryad deposits is in an S3 bucket administered and paid
for by Dryad, while Dash deposits (i.e., deposits from UC tenants),
are stored in an S3 bucket administered by CDL.


Interactions with Merritt
===========================

Submissions to Merritt can be started and stopped from the
[GUI Submission Queue page](https://datadryad.org/stash/submission_queue). However,
actions on this page will only affect the single server that you are
attached to, and not all servers in a load-balanced system. (Note
the long_jobs.dryad script will also do this,
also, on the current server). 

Stopping Merritt Submissions
-----------------------------

To pause Merritt submissions, on each server:
```
touch apps/ui/releases/hold-submissions.txt
```

This will put any queued submissions into the
`rejected_shutting_down` state on this server, which means they will
not be submitted right now, but you can restart them again afterward.

(Re)Starting Merritt Submissions from hold or Merritt errors
------------------------------------------------------------

To restart Merrit submissions, on each server:
```
rm apps/ui/releases/hold-submissions.txt
```

THEN, on one server, in the Rails console:
```
resource_ids =
  StashEngine::RepoQueueState.latest_per_resource.where(state: 'rejected_shutting_down').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
  StashEngine.repository.submit(resource_id: res_id)
end
```

If Merritt had errors, you can use a similar process, but you must remove any `processing` entries for
the RepoQueueState:
```
resource_ids =
  StashEngine::RepoQueueState.latest_per_resource.where(state: 'errored').order(:updated_at).map(&:resource_id)
resource_ids.each do |res_id|
 repo_queue_id = StashEngine::RepoQueueState.where(state: 'processing', resource_id: res_id).last.id
 StashEngine::RepoQueueState.find(repo_queue_id).destroy
 StashEngine.repository.submit(resource_id: res_id)
end
```

Merrit async download check
----------------------------

This error typically means that the account being used by the Dryad UI
to access Merritt does not have permisisons for the object being
requested. This is often because either the Dryad UI or the object in
Merritt is using a UC-based account, while the other is using a non-UC account.


Stash-Notifier
==============

The notifier runs from cron on our servers, as something like:
```
STASH_ENV=migration NOTIFIER_OUTPUT=stdout
/dryad/apps/stash-notifier/main.rb
```

In most cases, the servers have a `notifier_force.sh` script that will force the
notifier to run immediately, without waiting for the cron.

Note that it can only access Merritt when running from within the CDL
network (e.g., from the dryad-dev machine), or when proxied through
a privileged machine using a tool like `sshuttle`.

Sample call to test whether an OAI feed is reachable:
`curl "http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?verb=ListSets"`

Sample URLs harvesting from Merritt:
- http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?verb=ListMetadataFormats&set=cdl_dryaddev
- http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?verb=ListIdentifiers&set=cdl_dryaddev&metadataPrefix=oai_dc
- http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?verb=GetRecord&identifier=http://n2t.net/ark:/99999/fk40k3mc9f&metadataPrefix=stash_wrapper
- http://uc3-mrtoai-prd.cdlib.org:37001/mrtoai/oai/v2?verb=GetRecord&identifier=http://n2t.net/ark%3A%2F13030%2Fm5x97998&metadataPrefix=stash_wrapper

When the notifier sees something in the OAI feed, it makes a call to
Dryad like:
```
PATCH to #{MACHINE_NAME}/stash/dataset/doi:#{@doi}
{ 'record_identifier' => 'abc123', 'stash_version' => #{RESOURCE_ID} }
```

To bypass the notifier, and mark something submitted for testing
purposes (when it really hasn't been):
- wait a few minutes for the submission to time out
- `update stash_engine_resource_states set resource_state='submitted' where resource_id=<RESOURCE>;`
- `select max(id) from stash_engine_repo_queue_states where resource_id=<RESOURCE>;`
- `update stash_engine_repo_queue_states set state='completed' where id=<ID_FROM_ABOVE>;`

OR, to bypass the notifier in the ruby console, get the resource and insert a new curation
status:
```
r = StashEngine::Resource.last
act = StashEngine::CurationActivity.new(user_id: 1, status:
'submitted', note: 'bogus')
r.curation_activities << act
r.resource_states.first.resource_state='submitted'
r.resource_states.first.save!
r.repo_queue_states.last.state='completed'
r.repo_queue_states.last.save!
```

Testing the OAI-PMH feed we get from Merritt
--------------------------------------------

Sometimes it's not clear if Merritt is having a problem or if the
notifier is. The OAI-PMH feed is harvested and it is what triggers a
state change that shows a dataset has been successfully ingested. If a
dataset says on "processing" forever then it is likely that the
harvester isn't picking it up out of the OAI-PMH feed (Merritt
problem) or else there is some problem with our harvester or the
callback to our appliation which gets things updated.

Here are some sample queries to the OAI-PMH feed. They can usually be
done with a web browser (or CURL). However, the Merritt-production
feed is behind a firewall only accessible from our harvester server.

Get all the stash-wrapper items
forever: http://uc3-mrtoai-dev.cdlib.org:37001/mrtoai/oai/v2?verb=ListRecords&metadataPrefix=stash_wrapper

Additional query parameters:

- `from` and `until` can have iso8601 values to limit by date.
- Change the `metadataPrefix` to `oai_dc` to get Dublin Core or
  `dcs3.1` for DataCite 3.1.
- You can limit to a set of records with values such as `dataone_dash`, `lbnl_dash`, `ucb_dash`, `ucd_dash`...
  (You might need to check the config or with Merritt folks for specific collections).
  - There is an oai-pmh command to list all sets that may be helpful, for
    example: http://uc3-mrtoai-dev.cdlib.org:37001/mrtoai/oai/v2?verb=ListSets

An example of listing datasets with a date
range: http://uc3-mrtoai-dev.cdlib.org:37001/mrtoai/oai/v2?verb=ListRecords&metadataPrefix=dcs3.1&from=2018-01-01T21:33:11Z

An example of viewing a specific
dataset: http://uc3-mrtoai-stg.cdlib.org:37001/mrtoai/oai/v2?verb=GetRecord&identifier=http://n2t.net/ark:/99999/fk40k3mc9f&metadataPrefix=stash_wrapper

