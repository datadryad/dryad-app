require 'concurrent'

module Stash
  module Merritt
    class Submission
      attr_reader :resource_id
      attr_reader :ezid_client
      attr_reader :sword_params
      attr_reader :url_helpers

      def initialize(resource_id:, ezid_client:, sword_params:, url_helpers:)
        @resource_id = resource_id
        @ezid_client = ezid_client
        @sword_params = sword_params
        @url_helpers = url_helpers
      end

      def log
        Rails.logger
      end

      # TODO: move logic to stash-repo
      def submit
        mint_identifier_task = Stash::Merritt::Ezid::MintIdentifierTask.new(ezid_client: ezid_client)
        package_task = Stash::Merritt::PackageTask.new(resource_id: resource_id)
        sword_task = Stash::Merritt::SwordTask.new(sword_params)
        update_metadata_task = Stash::Merritt::Ezid::UpdateMetadataTask.new(ezid_client: ezid_client, url_helpers: url_helpers, resource_id: resource_id)
        package_cleanup_task = Stash::Merritt::PackageCleanupTask.new(resource_id: resource_id)

        # TODO: ActiveRecord connections?

        promise = [
              mint_identifier_task,
              package_task,
              sword_task,
              update_metadata_task,
              package_cleanup_task
          ].inject(nil) do |promise, task|
            promise ? promise.then { |prev_result| task.exec(prev_result) } : Concurrent::Promise.new { task.exec }
        end

        promise.on_success { |last_result| log.info("Success: #{last_result} ")}
        promise.rescue { |reason| log.error("Failure: #{reason}")}
      end
    end
  end
end
