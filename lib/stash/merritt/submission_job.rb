require 'stash/repo'
require 'stash/merritt/ezid_helper'
require 'stash/merritt/submission_package'
require 'stash/merritt/sword_helper'

module Stash
  module Merritt
    class SubmissionJob < Stash::Repo::SubmissionJob
      attr_reader :resource_id
      attr_reader :url_helpers

      def initialize(resource_id:, url_helpers:)
        @resource_id = resource_id
        @url_helpers = url_helpers
      end

      def submit!
        ezid_helper.ensure_identifier
        package = SubmissionPackage.new(resource: resource)
        sword_helper = SwordHelper.new(package: package, logger: log)
        sword_helper.submit!
        ezid_helper.update_metadata(dc3_xml: package.dc3_xml)
        package.cleanup!
      end

      private

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def ezid_helper
        @ezid_helper ||= EzidHelper.new(resource: resource, url_helpers: url_helpers)
      end
    end
  end
end
