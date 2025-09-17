# Dryad help center

The Dryad help center has a javascript/node based search feature (pagefind). When page content is added or updated, the pages need to be reindexed for this feature.

## Re-indexing instructions

1. Delete your local `public/cache` directory
2. Visit each html page linked in the help center to recreate the cache
3. run `yarn index:help` to recreate the index
