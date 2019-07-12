# frozen_string_literal: true

require_relative 'presenter'

module StashApi
  class File
    include StashApi::Presenter

    def initialize(file_id:)
      @se_file_upload = StashEngine::FileUpload.find(file_id)
      @resource = @se_file_upload.resource
    end

    def metadata
      { '_links': links }.merge(path: @se_file_upload.upload_file_name,
                                url: @se_file_upload.url,
                                size: @se_file_upload.upload_file_size,
                                mimeType: @se_file_upload.upload_content_type,
                                status: @se_file_upload.file_state,
                                digest: @se_file_upload.digest,
                                digestType: @se_file_upload.digest_type,
                                description: @se_file_upload.description).recursive_compact
    end

    def links
      basic_links.compact.merge(stash_curie)
    end

    def parent_version
      @version ||= Version.new(resource_id: @se_file_upload.resource_id)
    end

    private

    def basic_links
      hsh = {
        self: { href: api_url_helper.file_path(@se_file_upload.id) },
        'stash:dataset': { href: parent_version.parent_dataset.self_path },
        'stash:version': { href: parent_version.self_path },
        'stash:files': { href: parent_version.files_path },
        'stash:file-download': { href: api_url_helper.download_file_path(id: @se_file_upload.id) }
      }
      add_download!(hsh)
      hsh
    end

    def add_download!(hsh)
      # TODO: fix the download in here since it depends on the user's permission possibly
      hsh['stash:download'] = { href: api_url_helper.download_path(@se_file_upload.id) } if @se_file_upload.resource.submitted? &&
          @se_file_upload.resource.may_download?(ui_user: nil)
    end

  end
end
