module Stash
  module Harvester
    class Engine < ::Rails::Engine
      isolate_namespace Stash::Harvester
    end
  end
end
