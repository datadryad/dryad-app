module StashEngine
  module AdminDatasets
    class CurationTableRowPolicy < StashEngine::AdminDatasetsPolicy
      attr_reader :user, :dataset

      def initialize(user, dataset)
        super
        @user = user
        @dataset = dataset
      end

      def curation_activity_change?
        super &&
        dataset.resource&.permission_to_edit?(user: user) &&
        dataset.resource_state == 'submitted'
      end

      def current_editor_change?
        super &&
        dataset.resource&.permission_to_edit?(user: user) &&
        dataset.resource&.curatable?
      end

      def edit?
        (dataset.resource&.permission_to_edit?(user: user) && dataset.resource_state == 'submitted') ||
        (dataset.resource_state == 'in_progress' && dataset.resource.current_editor_id == user.id)
      end

    end
  end
end
