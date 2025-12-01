# Custom configuration for Solr

Currently we have only customized two files, `schema.xml` and `solrconfig.xml`

However, we're now including all the config files in the `config/solr_config` directory in our repository for ease
of installing or copying them over to the solr server.

Any additional changes we make to the SOLR server schema and configuration should be checked in and managed.

## The how to install and start SOLR

Download a SOLR binary release file from the Apache SOLR site.

Transfer this file to the target machine.

Extract SOLR to an appropriate directory like `tar zxf solr-x.y.z.tgz`.

```
cd ~/solr-9.7.0/
# Create a generic core in SOLR (inside base solr directory)
bin/solr create -c dryad
```

```
# get access to our github files like
cd ~
git clone git@github.com:datadryad/dryad-app.git
cd ~/solr-9.7.0/
cp dryad-app/config/solr_config/resources/* ./server/solr/dryad/conf
# remove the cloned repo if you wish like rm -rf dryad-app

# not sure this is needed, but those were permissions the solr script made when creating original schema.xml
chmod 775 ./server/solr/dryad/conf/schema.xml
```

```
# stop and restart solr (or just use restart)
cd ~/solr-9.7.0/
bin/solr stop
bin/solr start
```
