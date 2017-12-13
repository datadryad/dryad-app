module StashApi
  class Version

    attr_reader :resource
    def initialize(resource_id:)
      @resource = StashEngine::Resource.find(resource_id)
    end

    def metadata
      m = Metadata.new(resource: @resource)
      m.value
    end

    def metadata_with_links
      {'_links': links}.merge(metadata)
    end

    def parent_dataset
      @dataset ||= Dataset.new(identifier: @resource.identifier.to_s)
    end

    def self_path
      StashApi::Engine.routes.url_helpers.version_path(@resource.id)
    end

    def links
      {
          self: {href: self_path},
          'stash:dataset': {href: parent_dataset.self_path},
          'stash:files': {href: ''},
          'curies': [
              {
                  name: 'stash',
                  href: 'http://some.bogus.url',
                  templated: 'true'
              }
          ]
      }
    end
  end
end
