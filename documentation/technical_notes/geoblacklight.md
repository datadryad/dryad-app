# Information about Geoblacklight and SOLR

## Overview of config files

`stash/stash_datacite/lib/stash_indexer/indexing_resource.rb`
- Creates the actual document that will be sent to SOLR for indexing

`config/solr_config/schema.xml`
- Defines the fields that will be stored/indexed in SOLR
- Contains generic field names like "*_i", "*_sm", so fields can be added to the
  record without needing to change the schema or the SOLR server. Each of these
  field names has reasonable settings for stored/indexed/etc.
- Contains `copyField` declarations to copy fields into similar fields with
  suffixes like "*_tmi", so they can have varying weights in query processing
  (though it's unclear why we coudln't just use the original fields for this)
- Contains `copyField` declarations to ensure all textual fields are available
  for text searching

`config/solr_config/solrconfig.xml`
- Defines query handling.

`config/settings.yml`
- UI settings for GeoBlacklight


## How to add another facet to the data and search interface

1. Set up the additional item(s) in the SOLR schema for Geoblacklight
   - edit `config/solr_config/solrconfig.xml` in our code and add a facet field
      like those already shown. Look at the dynamic naming at the end `s` is for string,
      `m` is multiple, `i` is integer.  The `schema.xml` in same directory gives more info.
2. Edit `schema.xml` in this same directory.  Add a copyField for scoring or
   full-text search.  Follow the examples if you need to include in search or queryfilters. (see 3 below)
3. Back in `solrconfig.xml` add to the `qf` and `pf` sections (queryFilter and phraseBoost).
   These use the copied fields you set up in number 2.
4. You will need to copy (scp) these completed files into the geoblacklight core on
   each server you want to use it on.  Start by testing on dev.  The core is someplace
   like `~/apps/solr/server/solr/geoblacklight/conf`.  You'll need to restart SOLR
   afterwards (right now from `~/init.d` script).
5. Double-check search is still working as expected without error after restarting.
6. Add constants to the geoblacklight example and config for your new facet.
   `dryad-config-example/settings.yml` and `config/settings.yml`. For example
    ```ruby
    :DATASET_FILE_EXT: 'dryad_dataset_file_ext_sm'
    ```
7. Add indexing to populate the data you desire into each record at
   `stash/stash_datacite/lib/stash_indexer/indexing_resource.rb` and update the tests.
8. Update all the SOLR records: `RAILS_ENV=<env> bundle exec rails rsolr:reindex`
