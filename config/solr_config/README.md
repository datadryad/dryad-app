# Custom configuration for Solr/Geoblacklight

Dryad adds journal information to the standard Geoblacklight schema so that users can search for a publication DOI, manuscript number, or Pubmed ID. We also add a facet for the publication name.

Copy the following 2 XML files into the `/dryad/apps/solr/data/geoblacklight/conf/` directory on the Solr server(s).

Once the files are in place you will need to restart Solr.  Here are some examples of how to configure it once solr has been extracted/installed and it is started.

```
# Create a generic core in SOLR (inside base solr directory)
bin/solr create -c geoblacklight
```

```
# download and copy the geoblacklight schema to the core
mkdir tmp && cd tmp
wget -L https://github.com/geoblacklight/geoblacklight-schema/archive/v0.3.2.tar.gz
tar zxvf v0.3.2.tar.gz
cp geoblacklight-schema-0.3.2/conf/* ~/apps/solr/server/solr/geoblacklight/conf
```

```
# copy our customizations
cd ~/apps/solr/server/solr/geoblacklight/conf/
wget https://raw.githubusercontent.com/CDL-Dryad/dryad/master/config/solr_config/schema.xml
wget https://raw.githubusercontent.com/CDL-Dryad/dryad/master/config/solr_config/solrconfig.xml
```

```
# if wget saved the files with .1 extension instead of ovewriting
mv schema.xml schema.xml.old
mv solrconfig.xml solrconfig.xml.old
mv schema.xml.1 schema.xml
mv solrconfig.xml.1 solrconfig.xml
# not sure this is needed, but those were permissions the solr script made when creating original schema.xml
chmod 775 schema.xml
```

```
# stop and restart solr (or just use restart)
cd ~/apps/solr
bin/solr stop
bin/solr start
```
