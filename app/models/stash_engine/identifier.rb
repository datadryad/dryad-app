module StashEngine
  class Identifier < ActiveRecord::Base
    has_many :resources, :class_name => 'StashEngine::Resource'
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
