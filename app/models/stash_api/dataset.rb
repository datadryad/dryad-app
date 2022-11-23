# frozen_string_literal: true

require 'securerandom'
require_relative 'presenter'

module StashApi
  class Dataset
    include Presenter

    def initialize(identifier:, user: nil, item_view: false) # item view means not in list and may show more info for individual record
      id_type, iden = identifier.split(':', 2)
      @identifier_s = identifier
      @se_identifier = StashEngine::Identifier.where(identifier_type: id_type, identifier: iden).first
      @user = user
      @item_view = item_view
    end

    def last_se_resource
      @se_identifier.latest_viewable_resource(user: @user)
    end

    def last_version
      res = last_se_resource
      return nil unless res

      Version.new(resource_id: res.id, item_view: @item_view)
    end

    def metadata
      # descriptive metadata is initialized from the last version that
      # the user is allowed to see
      return simple_identifier if @se_identifier.nil?

      lv = last_version
      return simple_identifier if lv.nil?

      # expand the metadata with some dataset-level fields
      descriptive_hsh = descriptive_metadata_hash
      metadata = descriptive_hsh.merge(lv.metadata)
      add_license!(metadata)
      add_edit_link!(metadata, lv)

      # gives the links to nearby objects
      { _links: links }.merge(metadata).recursive_compact
    end

    def versions_path
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = api_url_helper.dataset_versions_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def version_path
      res = last_se_resource
      return nil unless res

      api_url_helper.version_path(res.id)
    end

    def self_path
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = api_url_helper.dataset_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def download_uri
      # rails will not encode an id with slashes automatically, and encoding it results in double-encoding
      return nil unless @se_identifier.latest_viewable_resource(user: @user)

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

    # a simple identifier without any versions, indicates that we created
    # an identifier that cannot be viewed
    def simple_identifier
      {
        identifier: @se_identifier&.to_s || @identifier_s,
        id: @se_identifier&.id,
        message: 'Identifier cannot be viewed. Either you lack permission to view it, or it is missing required elements.'
      }
    end

    def descriptive_metadata_hash
      {
        identifier: @se_identifier.to_s,
        id: @se_identifier.id,
        storageSize: @se_identifier.storage_size,
        relatedPublicationISSN: @se_identifier.publication_issn
      }
    end

    def add_license!(hsh)
      hsh[:license] = StashEngine::License.by_id(@se_identifier.license_id)[:uri] if @se_identifier.license_id
    end

    def add_edit_link!(hsh, version)
      ensure_edit_code
      return unless version.resource.permission_to_edit?(user: @user)

      hsh[:editLink] = "/stash/edit/#{CGI.escape(@se_identifier.to_s)}/#{@se_identifier.edit_code}"
    end

    def ensure_edit_code
      return if @se_identifier.edit_code

      @se_identifier.edit_code = SecureRandom.urlsafe_base64(10)
      @se_identifier.save
    end

  end
end
