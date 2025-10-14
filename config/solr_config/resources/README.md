# Custom configuration for Solr/Blacklight

Dryad adds journal information to the standard Blacklight schema so that users can search for a publication DOI, manuscript number, or Pubmed ID. We also add a facet for the publication name.

Currently we have only customized two files, `schema.xml` and `solrconfig.xml` compared to the default blacklight
configuration which is available from `https://github.com/projectblacklight/blacklight/archive/refs/tags/v8.6.1.tar.gz`.

However, we're now including all the config files in the `config/solr_config` directory in our repository for ease
of installing or copying them over to the solr server.

Any additional changes we make to the SOLR server schema and configuration should be checked in and managed.

## The how to install and start SOLR

Download a SOLR binary release file from the Apache SOLR site.

Transfer this file to the target machine.

Extract SOLR to an appropriate directory like `tar zxf solr-x.y.z.tgz`.

```
# Create a generic core in SOLR (inside base solr directory)
bin/solr create -c dryad
```

```
# get access to our github files like
git clone git@github.com:datadryad/dryad-app.git
cp dryad-app/config/solr_config/resources/* ~/apps/solr/server/solr/dryad/conf
# remove the cloned repo if you wish like rm -rf dryad-app

# not sure this is needed, but those were permissions the solr script made when creating original schema.xml
chmod 775 schema.xml
```

```
# stop and restart solr (or just use restart)
cd ~/apps/solr
bin/solr stop
bin/solr start
```
