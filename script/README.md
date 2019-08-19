# About the script directory

These are standalone scripts that we might use again and do
not require running under Rails or Rake.

For items that need to run in the Rails environment to
take advantage of its models and other files we are generally creating
Rake tasks under stash_engine\/lib\/tasks.  Those tasks will usually
be kept short and involve other ruby files.