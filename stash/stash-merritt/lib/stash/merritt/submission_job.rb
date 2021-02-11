require 'stash/repo'
require 'stash/doi/id_gen'
require 'stash/merritt/submission_package'
require 'stash/merritt/sword_helper'

module Stash
  module Merritt
    class SubmissionJob < Stash::Repo::SubmissionJob
      attr_reader :resource_id, :url_helpers

      # rubocop:disable Lint/MissingSuper
      def initialize(resource_id:, url_helpers:)
        @resource_id = resource_id
        @url_helpers = url_helpers
      end
      # rubocop:enable Lint/MissingSuper

      # this is where it actually starts running the real submission whenever it activates from the promise
      def submit!
        puts 'XXXXXXXX submission_job.submit! XXXXXXX'
        log.info("#{Time.now.xmlschema} #{description}")
        previously_submitted = StashEngine::RepoQueueState.where(resource_id: @resource_id, state: 'processing').count.positive?
        if Stash::Repo::Repository.hold_submissions?
          puts 'XXX sa'
          # to mark that it needs to be re-enqueued and processed later
          Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'rejected_shutting_down')
        elsif previously_submitted
          puts 'XXX sb'
          # Do not send to the repo again if it has already been sent. If we need to re-send we'll have to delete the statuses
          # and re-submit manually.  This should be an exceptional case that we send the same resource to Merritt more than once.
          latest_queue = StashEngine::RepoQueueState.latest(resource_id: @resource__id)
          latest_queue.destroy if latest_queue.present? && (latest_queue.state == 'enqueued')
        else
          puts 'XXX sc'
          Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'processing')
          do_submit!
        end
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
        puts 'XXXX ds a'
        package = create_package
        puts 'XXXX ds b'
        submit(package)
        puts 'XXXX ds c'
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
        puts 'XXXX cp a'
        id_helper.ensure_identifier
        log_info("creating package for resource #{resource_id} (#{resource.identifier_str})")
        # if resource.upload_type == :manifest
        # user-added URLs
        puts 'XXXX cp b'
        ObjectManifestPackage.new(resource: resource)
        # else
        # user-uploaded files
        #  ZipPackage.new(resource: resource)
        # end
      end

      def submit(package)
        log_info("submitting resource #{resource_id} (#{resource.identifier_str})")
        sword_helper = SwordHelper.new(package: package, logger: log)
        sword_helper.submit!
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
