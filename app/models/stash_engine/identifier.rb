module StashEngine
  class Identifier < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    def download_count
      self.join(resource: :resource_state)
      ResourceState.joins(resource: :identifier )
    end

    def view_count
      ResourceUsage.joins(resource: :identifier ).
          where("stash_engine_identifiers.identifier = ? AND stash_engine_identifiers.identifier_type = ?",
                identifier, identifier_type).sum(:views)
    end

    def download_count
      ResourceUsage.joins(resource: :identifier ).
          where("stash_engine_identifiers.identifier = ? AND stash_engine_identifiers.identifier_type = ?",
                identifier, identifier_type).sum(:downloads)
    end
  end
end
