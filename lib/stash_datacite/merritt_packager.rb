require 'stash_engine'
require 'stash_engine/sword/packager'
require 'stash_datacite'
require 'stash_datacite/resource_file_generation'

module StashDatacite
  # Creates a {Package} for submission to Merritt
  class MerrittPackager < StashEngine::Sword::Packager

    # Creates a new zipfile package
    #
    # @return [StashEngine::Sword::Package] a {Package}
    def create_package
      resource_file_generation = StashDatacite::ResourceFileGeneration.new(resource, tenant)
      identifier = resource_file_generation.identifier_str
      path = url_helpers.show_path(identifier)
      target_url = tenant.landing_url(path)
      folder = StashEngine::Resource.uploads_dir
      StashEngine::Sword::Package.new(
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
