require "stash_discovery/engine"

# http://stackoverflow.com/questions/5159607/rails-engine-gems-dependencies-how-to-load-them-into-the-application
# requires all dependencies
Gem.loaded_specs['stash_discovery'].dependencies.each do |d|
  begin
    require d.name
  rescue LoadError => e
    puts "Gem is causing load exception: \n #{e}"
  end
end


module StashDiscovery
end
