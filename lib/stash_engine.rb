# http://stackoverflow.com/questions/5159607/rails-engine-gems-dependencies-how-to-load-them-into-the-application
# requires all dependencies

Gem.loaded_specs['stash_engine'].dependencies.each do |d|
  require d.name
end

require "stash_engine/engine"

module StashEngine
end
