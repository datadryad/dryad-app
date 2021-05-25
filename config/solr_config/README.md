# Custom configuration for Solr/Geoblacklight

Dryad adds journal information to the standard Geoblacklight schema so that users can search for a publication DOI, manuscript number, or Pubmed ID. We also add a facet for the publication name.

Currently we have only customized two files, `schema.xml` and `solrconfig.xml` compared to the default geoblacklight
configuration which is available from `https://github.com/geoblacklight/geoblacklight-schema/archive/v0.3.2.tar.gz`.

However, we're now including all the config files in the `config/solr_config` directory in our repository for ease
of installing or copying them over to the solr server.

Any additional changes we make to the SOLR server schema and configuration should be checked in and managed.

## The how to install and start SOLR

extract SOLR to an appropriate directory like `tar zxf solr-x.y.z.tgz`.

```
# Create a generic core in SOLR (inside base solr directory)
bin/solr create -c geoblacklight
```

```
# get access to our github files like
git clone git@github.com:CDL-Dryad/dryad-app.git
cp dryad-app/config/solr-config/* ~/apps/solr/server/solr/geoblacklight/conf
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
