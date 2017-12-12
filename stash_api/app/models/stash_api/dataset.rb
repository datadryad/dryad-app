module StashApi
  class Dataset

    def initialize(identifier:)
      id_type, iden = identifier.split(':', 2)
      @se_identifier = StashEngine::Identifier.where(identifier_type: id_type, identifier: iden).first
    end

    def last_version
      return nil unless @se_identifier.resources.count > 0
      res_id = @se_identifier.resources.joins(:stash_version).order('version DESC').first.id
      Version.new(resource_id: res_id)
    end

    def metadata
      # gets descriptive metadata together
      lv = last_version
      return simple_identifier if lv.nil?
      metadata = {
          id: @se_identifier.to_s,
          storage_size: @se_identifier.storage_size,
      }.merge(lv.metadata)
      metadata.merge!({embargoEndDate: lv.resource.embargo.end_date.strftime('%Y-%m-%d')}) unless lv.resource.embargo.nil?
      metadata.delete_if { |k, v| v.blank? }

      # gives the furries and links to nearby objects
      {'_links': links}.merge(metadata)
    end

    def versions_path
      #rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = StashApi::Engine.routes.url_helpers.dataset_versions_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def self_path
      #rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = StashApi::Engine.routes.url_helpers.dataset_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def download_uri
      return nil unless @se_identifier.last_submitted_resource
      @se_identifier.last_submitted_resource.download_uri
    end

    def links
      {
          self: {href: self_path},
          'stash:versions': {href: versions_path},
          'stash:download': {href: download_uri},
          'curies': [
              {
                  name: 'stash',
                  href: 'http://some.bogus.url',
                  templated: 'true'
              }
          ]
      }
    end

    private

    # a simple identifier without any versions, shouldn't be happening but it did on dev at least
    def simple_identifier
      {
          id: @se_identifier.to_s,
          message: 'identifier is missing required elements'
      }
    end

  end
end