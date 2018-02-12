# frozen_string_literal: true

module StashApi
  class Dataset
    include StashApi::Presenter

    def initialize(identifier:)
      id_type, iden = identifier.split(':', 2)
      @se_identifier = StashEngine::Identifier.where(identifier_type: id_type, identifier: iden).first
    end

    def last_version
      return nil unless @se_identifier.resources.count.positive?
      res_id = @se_identifier.resources.joins(:stash_version).order('version DESC').first.id
      Version.new(resource_id: res_id)
    end

    def last_submitted
      return nil if @se_identifier.blank? || @se_identifier.resources.count < 1
      res_id = @se_identifier.last_submitted_resource
      return nil if res_id.nil?
      Version.new(resource_id: res_id)
    end

    def metadata
      # gets descriptive metadata together
      lv = last_submitted
      return simple_identifier if lv.nil?
      metadata = id_and_size_hash.merge(lv.metadata)
      add_embargo_date!(metadata, lv)
      metadata.delete_if { |_k, v| v.blank? }

      # gives the links to nearby objects
      { '_links': links }.merge(metadata)
    end

    def versions_path
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = api_url_helper.dataset_versions_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def version_path
      return nil unless last_submitted
      api_url_helper.version_path(last_submitted.resource.id)
    end

    def self_path
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = api_url_helper.dataset_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def download_uri
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      # @se_identifier.last_submitted_resource.download_uri
      return nil unless @se_identifier.last_submitted_resource
      path = api_url_helper.download_dataset_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def links
      {
        self: { href: self_path },
        'stash:versions': { href: versions_path },
        'stash:version': { href: version_path },
        'stash:download': { href: download_uri }
      }.merge(stash_curie)
    end

    private

    # a simple identifier without any versions, shouldn't be happening but it did on dev at least
    def simple_identifier
      {
        id: @se_identifier.to_s,
        message: 'identifier is missing required elements'
      }
    end

    def id_and_size_hash
      {
        id: @se_identifier.to_s,
        storage_size: @se_identifier.storage_size
      }
    end

    def add_embargo_date!(hsh, version)
      hsh[:embargoEndDate] = version.resource.embargo.end_date.strftime('%Y-%m-%d') unless version.resource.embargo.nil?
    end

  end
end
