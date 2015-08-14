module Stash
  module Harvester
    module Models
      STATUSES = [:pending, :in_progress, :completed, :failed]
      PENDING = STATUSES.index(:pending)
    end
  end
end
