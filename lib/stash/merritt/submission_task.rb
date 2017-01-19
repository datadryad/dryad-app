require 'stash/repo'

module Stash
  module Merritt
    class SubmissionTask < Stash::Repo::Task
      attr_reader :resource_id
      attr_reader :url_helpers

      def initialize(resource_id:, url_helpers:)
        @resource_id = resource_id
        @url_helpers = url_helpers
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def exec
        identifier_str = ezid_helper.ensure_identifier

      end

      private

      def ezid_helper
        @ezid_helper ||= EzidHelper.new(resource: resource, url_helpers: url_helpers)
      end

    end
  end
end
