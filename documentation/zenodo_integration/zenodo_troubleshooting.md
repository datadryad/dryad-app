
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
