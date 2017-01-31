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
        ensure_identifier
        package = create_package
        submit(package)
        update_metadata(package.dc3_xml)
        cleanup(package)
      end

      private

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def ezid_helper
        @ezid_helper ||= EzidHelper.new(resource: resource, url_helpers: url_helpers)
      end

      def ensure_identifier
        log.info("#{Time.now.xmlschema} #{self.class}: ensuring identifier for resource #{resource_id} (#{resource.identifier_str})")
        ezid_helper.ensure_identifier
      end

      def create_package
        log.info("#{Time.now.xmlschema} #{self.class}: creating package for resource #{resource_id} (#{resource.identifier_str})")
        SubmissionPackage.new(resource: resource)
      end

      def submit(package)
        log.info("#{Time.now.xmlschema} #{self.class}: submitting resource #{resource_id} (#{resource.identifier_str})")
        sword_helper = SwordHelper.new(package: package, logger: log)
        sword_helper.submit!
      end

      def update_metadata(dc3_xml)
        log.info("#{Time.now.xmlschema} #{self.class}: updating identifier metadata for resource #{resource_id} (#{resource.identifier_str})")
        ezid_helper.update_metadata(dc3_xml: dc3_xml)
      end

      def cleanup(package)
        log.info("#{Time.now.xmlschema} #{self.class}: cleaning up temporary files for resource #{resource_id} (#{resource.identifier_str})")
        package.cleanup!
      end

    end
  end
end
