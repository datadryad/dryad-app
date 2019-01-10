require 'stash/repo'
require 'stash/doi/id_gen'
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

      private

      def do_submit!
        package = create_package
        submit(package)
        # We don't update DataCite here now and only when embargoing or releasing datasets from curation
        # TODO: We should remove this cleanup and only cleanup once the harvester has called us back and Merritt was successful
        cleanup(package)
        Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      # :nocov:
      def tenant
        @tenant ||= resource.tenant
      end
      # :nocov:

      def id_helper
        @id_helper ||= Stash::Doi::IdGen.make_instance(resource: resource)
      end

      def create_package
        id_helper.ensure_identifier
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
