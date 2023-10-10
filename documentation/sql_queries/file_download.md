# Troubleshooting individual file download issues

The file model is deep in the heirarchy, so in order to get useful information
you need to join many tables and select the most relevant information.

Some useful example queries, below.  Replace the items in the WHERE clause with your values.

```sql
/* get information about the file and up to the identifier */
SELECT gf.id file_id, gf.upload_file_name, res.id resource_id, res.identifier_id,
       ids.identifier, res.download_uri, vers.version, vers.merritt_version
FROM stash_engine_resources res
    JOIN stash_engine_generic_files gf
        ON res.id = gf.resource_id
    JOIN stash_engine_identifiers ids
        ON res.identifier_id = ids.id
    JOIN stash_engine_versions vers
        ON res.id = vers.resource_id
WHERE gf.id = 102442;
```

```sql
/* get information about this file over time through different version */
SELECT ids.identifier, gf.id as file_id, res.identifier_id, res.id as resource_id,
       gf.upload_file_name, gf.upload_file_size, gf.file_state, vers.version, vers.merritt_version
FROM stash_engine_resources res
    JOIN stash_engine_generic_files gf
        ON res.id = gf.resource_id
    JOIN `stash_engine_resource_states` sers
        ON sers.resource_id = res.id
    JOIN stash_engine_versions vers
        ON res.id = vers.resource_id
    JOIN stash_engine_identifiers ids
        ON res.identifier_id = ids.id
WHERE res.identifier_id = 27114 AND
      gf.upload_file_name = 'kinesis & standard errors (by species).csv';
```

To examine the files in S3, you can look in the web console and brows to the correct bucket and path.

When you're inside a path such as `13030` you may want to filter to something like `m500516c|1|producer` to
see what files actually exist in different versions there.  (The `|` is a delimiter between the parts of the
end of the ark, version and we're concerned with producer files here.