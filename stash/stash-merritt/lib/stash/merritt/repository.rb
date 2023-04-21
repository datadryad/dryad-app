require_relative '../../../../../lib/stash/repo'
require 'stash/merritt/submission_job'
require_relative '../../../../../lib/stash/doi/id_gen'
require 'erb'

module Stash
  module Merritt
    class Repository < Stash::Repo::Repository

      ARK_PATTERN = %r{ark:/[a-z0-9]+/[a-z0-9]+}

      def create_submission_job(resource_id:)
        SubmissionJob.new(resource_id: resource_id, url_helpers: url_helpers)
      end

      def download_uri_for(record_identifier:)
        merritt_host = APP_CONFIG[:repository][:domain]
        ark = ark_from(record_identifier)
        "#{merritt_host}/d/#{ERB::Util.url_encode(ark)}"
      end

      def update_uri_for(resource:, record_identifier:) # rubocop:disable Lint/UnusedMethodArgument
        sword_endpoint = APP_CONFIG[:repository][:endpoint]
        doi = resource.identifier_str
        edit_uri_base = sword_endpoint.sub('/collection/', '/edit/')
        "#{edit_uri_base}/#{ERB::Util.url_encode(doi)}"
      end

      private

      def ark_from(record_identifier)
        ark_match_data = record_identifier && record_identifier.match(ARK_PATTERN)
        raise ArgumentError, "No ARK found in record identifier #{record_identifier || 'nil'}" unless ark_match_data

        ark_match_data[0].strip
      end
    end
  end
end
