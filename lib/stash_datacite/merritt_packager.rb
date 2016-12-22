require 'stash_engine'
require 'stash_datacite'
require 'stash_datacite/resource_file_generation'

module StashDatacite
  # Creates a {SwordPackage} for submission to Merritt
  class MerrittPackager
    attr_reader :resource
    attr_reader :tenant
    attr_reader :url_helpers
    attr_reader :request_host
    attr_reader :request_port

    def initialize(resource:, tenant:, url_helpers:, request_host:, request_port:)
      @resource = resource
      @tenant = tenant
      @url_helpers = url_helpers
      @request_host = request_host
      @request_port = request_port
    end

    # Creates a new zipfile package
    #
    # @return [StashEngine::SwordJob::SwordPackage] a {SwordPackage} 
    def create_package
      resource_file_generation = StashDatacite::ResourceFileGeneration.new(resource, tenant)
      identifier = resource_file_generation.identifier_str
      path = url_helpers.show_path(identifier)
      target_url = tenant.landing_url(path)
      folder = StashEngine::Resource.uploads_dir
      StashEngine::SwordJob::SwordPackage.new(
        title: main_title(resource),
        doi: identifier,
        zipfile: resource_file_generation.generate_merritt_zip(folder, target_url),
        resource_id: resource.id,
        sword_params: tenant.sword_params,
        request_host: request_host,
        request_port: request_port
      )
    end

    private
    
    def main_title(resource)
      title = resource.titles.where(title_type: nil).first
      title.try(:title)
    end
  end
end
