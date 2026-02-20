require 'active_support/concern'

module StashEngine
  module Support
    module Statuses
      extend ActiveSupport::Concern

      def current_curation_status
        reload
        last_curation_activity&.status
      end

      def status_published? = status_group[:published].includes?(current_curation_status)

      def first_submitted_status = first_status_activity(status_group[:submitted])
      def first_curated_status = first_status_activity(status_group[:curated])
      def first_published_status = first_status_activity(status_group[:published])
      def last_submitted_status = last_status_activity(status_group[:submitted])
      def last_curated_status = last_status_activity(status_group[:curated])
      def last_published_status = last_status_activity(status_group[:published])

      def first_status_activity(statuses)
        curation_activities.where(status: statuses).order(id: :asc).first
      end

      def last_status_activity(statuses)
        curation_activities.where(status: statuses).order(id: :desc).first
      end

      private

      def status_group
        {
          submitted: %w[peer_review awaiting_payment queued],
          curated: %w[published to_be_published embargoed action_required],
          published: %w[published embargoed retracted]
        }
      end
    end
  end
end
