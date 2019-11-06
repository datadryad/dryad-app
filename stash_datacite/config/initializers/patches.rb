require 'stash_datacite/author_patch'
require 'stash_datacite/user_patch'

# Note that this initializer WILL NOT get called in dev when reloading
# after an MVC class change; in that case we need to call patch! explicitly
# before it's needed. See e.g. Completions#initialize().

# TODO: some trick with require_dependency?

# Ensure Author-Affiliation relation & related methods
StashDatacite::AuthorPatch.patch! unless StashEngine::Author.method_defined?(:affiliation)
StashDatacite::UserPatch.patch! unless StashEngine::User.method_defined?(:affiliation)
