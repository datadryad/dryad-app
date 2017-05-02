require 'stash/repo'
require 'stash/merritt/submission_job'
require 'erb'

module Stash
  module Merritt
    class Repository < Stash::Repo::Repository

      ARK_PATTERN = %r{ark:/[a-z0-9]+/[a-z0-9]+}

      def initialize(url_helpers:)
        super
      end

      def create_submission_job(resource_id:)
        SubmissionJob.new(resource_id: resource_id, url_helpers: url_helpers)
      end

      def download_uri_for(resource_id:, record_identifier:)
        merritt_host = merritt_host_for(resource_id)
        ark = ark_from(record_identifier)
        "http://#{merritt_host}/d/#{ERB::Util.url_encode(ark)}"
      end

      def update_uri_for(resource_id:, record_identifier:) # rubocop:disable Lint/UnusedMethodArgument
        sword_endpoint = sword_endpoint_for(resource_id)
        doi = doi_for(resource_id)
        edit_uri_base = sword_endpoint.sub('/collection/', '/edit/')
        "#{edit_uri_base}/#{ERB::Util.url_encode(doi)}"
      end

      private

      def merritt_host_for(resource_id)
        repo_params_for(resource_id).domain
      end

      def sword_endpoint_for(resource_id)
        repo_params_for(resource_id).endpoint
      end

      def repo_params_for(resource_id)
        tenant = tenant_for(resource_id)
        tenant.repository
      end

      def tenant_for(resource_id)
        resource = StashEngine::Resource.find(resource_id)
        resource.tenant
      end

      def doi_for(resource_id)
        resource = StashEngine::Resource.find(resource_id)
        resource.identifier_str
      end

      def ark_from(record_identifier)
        ark_match_data = record_identifier && record_identifier.match(ARK_PATTERN)
        raise ArgumentError, "No ARK found in record identifier #{record_identifier || 'nil'}" unless ark_match_data
        ark_match_data[0].strip
      end
    end
  end
end
