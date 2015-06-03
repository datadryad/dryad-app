# Stash::Harvester

Harvests metadata from a digital repository into
[Solr](http://lucene.apache.org/solr/) for indexing.

## OAI-PMH support

The `Stash::Harvester::OAIPMH` module harvests metadata from an [OAI-PMH](http://www.openarchives.org/pmh/) repoistory.

## ResourceSync support

The `Stash::Harvester::Resync` module harvests metadata from a [ResourceSync](http://www.openarchives.org/rs/1.0/resourcesync) source. It makes the following assumptions:

1. Metadata is a first-class resource with its own lifecycle, its own published change lists, etc.
2. A [Capability List](http://www.openarchives.org/rs/1.0/resourcesync#CapabilityList) exists, at a well-known URI, to advertise the metadata resources and their changes.
3. This Capability List advertises a [Change List](http://www.openarchives.org/rs/1.0/resourcesync#ChangeList), a [Change Dump](http://www.openarchives.org/rs/1.0/resourcesync#ChangeDump), or both.
  * As implied (though not explicitly stated) by the ResourceSync spec, if both a Change List and a Change Dump exist, all changes in the Change List are also in a corresponding Change Dump. That is, wherever both exist, it is sufficient to examine only one or the other.
4. The Change List / Change Dump resources advertised in the Capability List may be either single lists / dumps or [Change List Indices](http://www.openarchives.org/rs/1.0/resourcesync#ChangeListIndex) / [Change Dump Indices](http://www.openarchives.org/rs/1.0/resourcesync#ChangeDumpIndex), as advertised in the spec.

---

## Useful links

- [Travis continuous integration](https://travis-ci.org/CDLUC3/stash-harvester)


