module StashEngine
  module Concerns
    module ResourceUpdated
      extend ActiveSupport::Concern

      included do
        after_save :update_updated_at
        after_destroy :update_updated_at
      end

      def update_updated_at
        StashEngine::Resource.where(id: resource_id).update_all(updated_at: Time.current)
      end
    end
  end
end
