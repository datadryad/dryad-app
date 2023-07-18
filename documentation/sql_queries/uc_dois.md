## Find the UC DOIs we want to transfer to DataCite

```sql
SELECT * 
	FROM `stash_engine_identifiers`
	WHERE `identifier` NOT LIKE '10.5061%'
	AND pub_state IN ('published', 'embargoed', 'withdrawn');
```

## UC DOIs that have been minted by EZID but don't have metadata associated yet
We probably want to transfer these, also, since they may become real DOIs upon
publication and the DOI has already been assigned to the dataset
and possibly has already been shared with others.

If these can't be transferred then we need to change the DOIs to a Dryad one.

```mysql
SELECT * 
	FROM `stash_engine_identifiers`
	WHERE `identifier` NOT LIKE '10.5061%'
	AND pub_state NOT IN ('published', 'embargoed', 'withdrawn');
```

## Items not submitted to Merritt and over a year old

This is helpful because we do not need to recreate these in DataCite, but there
are only about 103 out of 750 unpublished right now.

```mysql
SELECT DISTINCT ids.* 
	FROM `stash_engine_identifiers` ids
		JOIN stash_engine_resources res
			ON ids.id = res.identifier_id
		JOIN (SELECT max(id) as res_id FROM stash_engine_resources GROUP BY identifier_id) last_res
			ON res.id = last_res.res_id
		JOIN stash_engine_versions ver
			ON res.id = ver.resource_id
		JOIN stash_engine_resource_states rs
		   ON res.id = rs.resource_id
   	WHERE ids.identifier NOT LIKE '10.5061%'
		AND ids.pub_state NOT IN ('published', 'embargoed', 'withdrawn')
		AND ver.version < 2 AND rs.resource_state <> 'submitted' AND ids.created_at < "2022-07-17";
```
