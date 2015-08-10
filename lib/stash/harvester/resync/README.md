## ResourceSync harvesting

### Assumptions

1. Metadata is a first-class resource with its own lifecycle, its own published change lists, etc.
2. A [Capability List](http://www.openarchives.org/rs/1.0/resourcesync#CapabilityList) exists, at a well-known URI, to advertise the metadata resources and their changes.
3. This Capability List advertises a [Change List](http://www.openarchives.org/rs/1.0/resourcesync#ChangeList), a [Change Dump](http://www.openarchives.org/rs/1.0/resourcesync#ChangeDump), or both.
  * As implied (though not explicitly stated) by the ResourceSync spec, if both a Change List and a Change Dump exist, all changes in the Change List are also in a corresponding Change Dump. That is, wherever both exist, it is sufficient to examine only one or the other.
4. The Change List / Change Dump resources advertised in the Capability List may be either single lists / dumps or [Change List Indices](http://www.openarchives.org/rs/1.0/resourcesync#ChangeListIndex) / [Change Dump Indices](http://www.openarchives.org/rs/1.0/resourcesync#ChangeDumpIndex), as advertised in the spec.

### Configuration

A YAML configuration file must be provided containing:

- `capability_list_url`: the URL of the capability list for metadata resources, as described above

### Workflow

1. Get the (well-known) Capability List for the metadata.
2. For baseline synchronization:
    - if a Resource Dump exists, get that, and
        - if it's a plain dump, get each bitstream package, and
            - extract each resource from the package
        - if it's a Resource Dump Index, flatten to download each bitstream package in each described dump, then extract each resource from each package
    - otherwise, get the Resource List, and
        - if it's a plain list, download each resource
        - if it's a Resource List Index, flatten to download each resource in each described list
3. For incremental synchronization:
    - given a start and end timestamp range:
        - if a Change Dump exists, get that
          - if it's a plain dump
            - filter to find and download all bitstream packages that intersect the specified range
            - for each of those, find all changes that fall within the specified range (inclusive)
                - find the latest change for each resource, then extract those from the package
          - if it's a Change Dump Index:
            - find all dumps that intersect the specified range
            - filter and download each as above
        - otherwise, get the Change List and,
          - if it's a plain list, filter it for changes that fall within the specified range (inclusive)
                - find the latest change for each resource, then download those
          - if it's a Change List Index:
            - find all lists that intersect the specified range
            - filter each of those and download as above
