# Dryad help center

The Dryad help center has a javascript/node based search feature (pagefind). When page content is added or updated, the pages need to be reindexed for this feature. This happens automatically during deployment, and can be done manually for development.

## Re-indexing instructions

1. Delete your local `public/cache` directory
2. run `bundle exec rails help_cache` to recreate the cache
3. run `yarn index:help` to recreate the index
