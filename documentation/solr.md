# How to backup or repopulate SOLR indexes

## SOLR Setup

Right now our SOLR setup is quite manual and we manually copy over some configuration files to the SOLR server.
We also manually create the core. It is fairly simple to run SOLR since it's a Java application that can
be extracted and run.

The [README.md](config/solr_config/README.md) details how to set up the geoblacklight core and schema and
our additions to it, which should always be checked into our repository after we make updates to the
schema.

## Adding data to SOLR

We haven't done formal backups of the SOLR data since it is fairly easy to repopulate from our database
and in fact we have regenerated it on multiple occasions (every time we make schema changes or add facets).

The [rsolr:reindex](lib/tasks/rsolr.rake) rake task is used to repopulate the SOLR index from the database
and it runs quickly (somewhere in the range of a few minutes to a couple hours if I recall).

## Backing up SOLR

SOLR also offers a backup and restore functionality, so it could be manually backed up from one server and
restored onto another.  The [SOLR backup and restore documentation](https://solr.apache.org/guide/solr/latest/deployment-guide/backup-restore.html)
gives information about how to back up a core and restore it.

While it's possible to use this option rather than repopulating the indexes from the database, I suspect it
would not offer much of an advantage over running the repopulation rake task.  There may be other reasons
we want to keep backups or automate them, though.