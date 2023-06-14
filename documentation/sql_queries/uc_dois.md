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
