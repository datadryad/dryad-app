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
cd ~/dryad-app/config/solr_config/resources 
docker cp protwords.txt dryad_solr:/var/solr/data/dryad/conf/protwords.txt
docker cp README.md dryad_solr:/var/solr/data/dryad/conf/README.md
docker cp schema.xml dryad_solr:/var/solr/data/dryad/conf/schema.xml
docker cp solrconfig.xml dryad_solr:/var/solr/data/dryad/conf/solrconfig.xml
docker cp stopwords_en.txt dryad_solr:/var/solr/data/dryad/conf/stopwords_en.txt
docker cp synonyms.txt dryad_solr:/var/solr/data/dryad/conf/synonyms.txt
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
cd ~/dryad-app/config/solr_config/rors 
docker cp protwords.txt dryad_solr:/var/solr/data/rors/conf/protwords.txt
docker cp README.md dryad_solr:/var/solr/data/rors/conf/README.md
docker cp schema.xml dryad_solr:/var/solr/data/rors/conf/schema.xml
docker cp solrconfig.xml dryad_solr:/var/solr/data/rors/conf/solrconfig.xml
docker cp stopwords_en.txt dryad_solr:/var/solr/data/rors/conf/stopwords_en.txt
docker cp synonyms.txt dryad_solr:/var/solr/data/rors/conf/synonyms.txt
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

Test ENV SOLR Setup
===========

See [here](docker_test_solr.md) more details on installation and usage.