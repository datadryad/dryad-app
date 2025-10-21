# Custom configuration for Solr/Rors

Dryad indexes ROR information so that scripts and user searches run faster and do not add extra load on the database.

All the config files can be found in `config/solr_config/rors` directory in our repository for ease
of installing or copying them over to the solr server.

Any additional changes we make to the SOLR server schema and configuration should be checked in and managed.

## The how to install and start SOLR

Download a SOLR binary release file from the Apache SOLR site.

Transfer this file to the target machine.

Extract SOLR to an appropriate directory like `tar zxf solr-x.y.z.tgz`.

*NOTE: In case you already have SOLR installed, you can skip the above steps*

```
cd ~/solr-9.7.0/
# Create a generic core in SOLR (inside base solr directory)
bin/solr create -c rors
```

```
# get access to our github files like
cd ~
git clone git@github.com:datadryad/dryad-app.git
cd ~/solr-9.7.0/
cp dryad-app/config/solr_config/rors/* ./server/solr/rors/conf
# remove the cloned repo if you wish like rm -rf dryad-app

# not sure this is needed, but those were permissions the solr script made when creating original schema.xml
chmod 775 ./server/solr/rors/conf/schema.xml
```

```
# stop and restart solr (or just use restart)
cd ~/solr-9.7.0/
bin/solr stop
bin/solr start
```
