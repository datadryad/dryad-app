module Stash
  module Harvester
    class Engine < ::Rails::Engine
      isolate_namespace Harvester
    end
  end
end
