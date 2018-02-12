# frozen_string_literal: true

module StashApi
  class Version
    include StashApi::Presenter

    attr_reader :resource
    def initialize(resource_id:)
      @resource = StashEngine::Resource.find(resource_id)
    end

    def metadata
      m = Metadata.new(resource: @resource)
      m.value.delete_if { |_k, v| v.blank? }
    end

    def metadata_with_links
      { '_links': links }.merge(metadata)
    end

    def parent_dataset
      @dataset ||= Dataset.new(identifier: @resource.identifier.to_s)
    end

    def self_path
      api_url_helper.version_path(@resource.id)
    end

    def files_path
      api_url_helper.version_files_path(@resource.id)
    end

    def links
      {
        self: { href: self_path },
        'stash:dataset': { href: parent_dataset.self_path },
        'stash:files': { href: files_path },
        'stash:download': { href: api_url_helper.download_version_path(@resource.id) } # was @resource.merritt_producer_download_uri
      }.merge(stash_curie)
    end
  end
end
