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
        resource = StashEngine::Resource.find(resource_id)
        ezid_helper = EzidHelper.new(resource: resource, url_helpers: url_helpers)
        ezid_helper.ensure_identifier
        package = SubmissionPackage.new(resource: resource)
        sword_helper = SwordHelper.new(package: package, logger: log)
        sword_helper.submit!
        ezid_helper.update_metadata(dc3_xml: package.dc3_xml)
        package.cleanup!
      end
    end
  end
end
