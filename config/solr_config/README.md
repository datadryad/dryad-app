# Custom configuration for Solr/Geoblacklight

Dryad adds journal information to the standard Geoblacklight schema so that users can search for a publication DOI, manuscript number, or Pubmed ID. We also add a facet for the publication name.

Copy the following 2 XML files into the `/dryad/apps/solr/data/geoblacklight/conf/` directory on the Solr server(s).

Once the files are in place you will need to restart Solr. Please see the [dryad installation instructions](https://github.com/CDL-Dryad/dryad/blob/master/documentation/dryad_install.md) for more information on starting/stopping Solr.
