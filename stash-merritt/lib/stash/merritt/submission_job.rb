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
        log.info("#{Time.now.xmlschema} #{description}")
        do_submit!
      rescue StandardError => e
        Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: e)
      end

      def description
        @description ||= begin
          resource = StashEngine::Resource.find(resource_id)
          description_for(resource)
        rescue StandardError => e
          log.error("Can't find resource #{resource_id}: #{e}\n#{e.backtrace.join("\n")}")
          "#{self.class} for missing resource #{resource_id}"
        end
      end

      # :nocov:
      # TODO: couldn't figure out how to test this, maybe ask David when he gets back
      def update_identifier_metadata!
        resource = StashEngine::Resource.find(@resource_id)
        sp = Stash::Merritt::SubmissionPackage.new(resource: resource, packaging: nil)
        dc4_xml = sp.dc4_builder.contents
        update_metadata(dc4_xml)
      end
      # :nocov:

      private

      def do_submit!
        package = create_package
        submit(package)
        update_metadata(package.dc4_xml)
        cleanup(package)
        Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def tenant
        @tenant ||= resource.tenant
      end

      def landing_page_url
        @landing_page_url ||= begin
          path_to_landing = url_helpers.show_path(resource.identifier_str)
          tenant.full_url(path_to_landing)
        end
      end

      def ezid_helper
        @ezid_helper ||= EzidHelper.new(resource: resource)
      end

      def ensure_identifier
        return if resource.identifier
        log_info("minting new identifier for resource #{resource_id}")
        resource.ensure_identifier(ezid_helper.mint_id)
      end

      def create_package
        ensure_identifier
        log_info("creating package for resource #{resource_id} (#{resource.identifier_str})")
        if resource.upload_type == :manifest
          ObjectManifestPackage.new(resource: resource)
        else
          ZipPackage.new(resource: resource)
        end
      end

      def submit(package)
        log_info("submitting resource #{resource_id} (#{resource.identifier_str})")
        sword_helper = SwordHelper.new(package: package, logger: log)
        sword_helper.submit!
      end

      def update_metadata(dc4_xml)
        log_info("updating identifier landing page (#{landing_page_url}) and metadata for resource #{resource_id} (#{resource.identifier_str})")
        ezid_helper.update_metadata(dc4_xml: dc4_xml, landing_page_url: landing_page_url)
      end

      def cleanup(package)
        log_info("cleaning up temporary files for resource #{resource_id} (#{resource.identifier_str})")
        package.cleanup!
      end

      def description_for(resource)
        msg = "#{self.class} for resource #{resource_id} (#{resource.identifier_str}): "
        msg << if (update_uri = resource.update_uri)
                 "posting update to #{update_uri}"
               else
                 "posting new object to #{resource.tenant.sword_params[:collection_uri]}"
               end
        msg << " (tenant: #{resource.tenant_id})"
      end

      def log_info(message)
        log.info("#{Time.now.xmlschema} #{self.class}: #{message}")
      end
    end
  end
end
