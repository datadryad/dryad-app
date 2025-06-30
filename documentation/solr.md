
SOLR Setup
===========

Our SOLR setup is quite manual and we manually copy over some configuration files to the SOLR server.
We also manually create the core. It is fairly simple to run SOLR since it's a Java application that can
be extracted and run.

The [README.md](config/solr_config/README.md) details how to set up the blacklight core and schema and
our additions to it, which should always be checked into our repository after we make updates to the
schema.

Config files
------------

- solrconfig.xml - basic SOLR server config
- schema.xml - fields to store and how they are processed
- stopwords.txt - basic "meaningless" words that will be ignored
- stopwords_en.txt - stopwords specific to English
- synonyms.txt - words that should be indexed/queried together
- blacklight.yml - basic Blacklight config
- settings.yml - Blacklight config


Adding data to SOLR
====================

The [rsolr:reindex](lib/tasks/rsolr.rake) rake task is used to repopulate the SOLR index from the database
and it runs quickly (somewhere in the range of a few minutes to a couple hours if I recall).

Using SOLR
===========

The Dryad search API is largely a passthrough to SOLR. See the [search API documentation](apis/search.md) for details.

SOLR UI
--------

If you want to view a live SOLR, you need to add your local IP to the relevant
SOLR security group, and access its specific port, e.g.,
http://34.222.121.163:8983/

To get details about terms in the index:
1. select "dryad" core in the left menu
2. select Schema
3. select a field
4. Load Term Info

About indexes:
- Fields with _s are the original string
- _sort is a processed version suitable for sorting
- _ti is tokenized for searching in the index

Query parsing
-------------

SOLR has the notion of a "default" field that responses to unstructured queries.
You can always override this by specifying a field name in the query.

- [Basic overview of SOLR queries](https://yonik.com/solr/query-syntax/)
- [Full details in the SOLR
- docs](https://solr.apache.org/guide/6_6/the-standard-query-parser.html)


Security
========

- The SOLR application has no internal security -- anyone who has access can add/delete documents
- We do security by limiting access to the relevant EC2 IP addresses. If you start/stop one of the Dryad servers, it may be assigned a
  new IP address, which will cause searches to be blocked by the SOLR server's
  security group. You will need to edit the security group to allow the Rails
  server to access SOLR again. 


Backing up SOLR
===============

We haven't done formal backups of the SOLR data since it is fairly easy to repopulate from our database
and in fact we have regenerated it on multiple occasions (every time we make schema changes or add facets).

SOLR also offers a backup and restore functionality, so it could be manually backed up from one server and
restored onto another. The [SOLR backup and restore documentation](https://solr.apache.org/guide/solr/latest/deployment-guide/backup-restore.html)
gives information about how to back up a core and restore it.

While it's possible to use this option rather than repopulating the indexes from the database, I suspect it
would not offer much of an advantage over running the repopulation rake task. There may be other reasons
we want to keep backups or automate them, though.

