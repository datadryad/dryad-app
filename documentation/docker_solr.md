Docker Setup
===========

A very easy method to manage containerized applications is Docker Desktop.

See [here](https://docs.docker.com/desktop/) more details on installation and usage.

SOLR Setup
===========

## Create docker container with SORL version 9.7.0
```
docker run --name dryad_solr -d -p 8983:8983 -t solr:9.7.0
```

## Set up `dryad` core, used for main application search
Create the core
```
docker exec -it --user solr dryad_solr bin/solr create_core -c dryad
```
Copy all configuration files
```
docker cp ~/dryad-app/config/solr_config/resources/protwords.txt dryad_solr_9:/var/solr/data/dryad/conf/
docker cp ~/dryad-app/config/solr_config/resources/README.md dryad_solr_9:/var/solr/data/dryad/conf/
docker cp ~/dryad-app/config/solr_config/resources/schema.xml dryad_solr_9:/var/solr/data/dryad/conf/
docker cp ~/dryad-app/config/solr_config/resources/solrconfig.xml dryad_solr_9:/var/solr/data/dryad/conf/
docker cp ~/dryad-app/config/solr_config/resources/stopwords_en.txt dryad_solr_9:/var/solr/data/dryad/conf/
docker cp ~/dryad-app/config/solr_config/resources/synonyms.txt dryad_solr_9:/var/solr/data/dryad/conf/
```

Restart container for new config to apply
```
docker stop dryad_solr
docker start dryad_solr
```

Data indexing
```
rake rsolr:reindex
```

## Set up `rors` core, used for scripts and ROR searches
Create the core
```
docker exec -it --user solr dryad_solr bin/solr create_core -c rors
```
Copy all configuration files
```
docker cp ~/dryad-app/config/solr_config/rors/protwords.txt dryad_solr_9:/var/solr/data/rors/conf/
docker cp ~/dryad-app/config/solr_config/rors/README.md dryad_solr_9:/var/solr/data/rors/conf/
docker cp ~/dryad-app/config/solr_config/rors/schema.xml dryad_solr_9:/var/solr/data/rors/conf/
docker cp ~/dryad-app/config/solr_config/rors/solrconfig.xml dryad_solr_9:/var/solr/data/rors/conf/
docker cp ~/dryad-app/config/solr_config/rors/stopwords_en.txt dryad_solr_9:/var/solr/data/rors/conf/
docker cp ~/dryad-app/config/solr_config/rors/synonyms.txt dryad_solr_9:/var/solr/data/rors/conf/
```

Restart container for new config to apply
```
docker stop dryad_solr
docker start dryad_solr
```

Data indexing
```
rails console
>> StashEngine::RorOrg.reindex_all
```
