Recovering datasets that were removed in The Great Purge
========================================================

Retrieve metadata
-----------------

Get all metadata from the old database. It can be accessed from the prod-1
server by using the script `mysql_prod_pre_abandoned.sh`. For now, we don't have
a formal process for this; just copy the appropriate metadata from the database
into the submission UI.

Important: If you are "restoring" a dataset that needs a particular DOI, ensure
that the DOI is corrected in the Identifier table before the dataset is
published.


Retrieve files
--------------

1. In the database, get the resource ID and associated Merritt ARK:
   `select id,download_uri from stash_engine_resources where identifier_id=74448;`
2. Locate the files. In S3, go to the production bucket,
  `dryad-assetstore-merritt-west`. Older files will be stored under the ARK
  hirearcy. Newer files will be stored under `v3`, using the resource ID. Since
  these files have been "deleted", you will need to turn on the "Show versions"
  toggle.
3. Restore/download the files.

