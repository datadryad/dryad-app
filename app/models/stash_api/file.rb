# frozen_string_literal: true

require_relative 'presenter'
module StashApi
  class File
    include Presenter

    def initialize(file_id:, user: nil)
      @se_data_file = StashEngine::DataFile.find(file_id)
      @resource = @se_data_file.resource
      @user = user
    end

    def metadata
      { _links: links }.merge(path: @se_data_file.download_filename,
                              size: @se_data_file.upload_file_size,
                              mimeType: @se_data_file.upload_content_type,
                              status: @se_data_file.file_state,
                              digest: @se_data_file.digest,
                              digestType: @se_data_file.digest_type,
                              description: @se_data_file.description).recursive_compact
    end

    def metadata_with_url
      { url: @se_data_file.url }.merge(metadata)
    end

    def links
      basic_links.compact.merge(stash_curie)
    end

    def parent_version
      @version ||= Version.new(resource_id: @se_data_file.resource_id)
    end

    private

    def basic_links
      hsh = {
        self: { href: api_url_helper.file_path(@se_data_file.id) },
        'stash:dataset': { href: parent_version.parent_dataset.self_path },
        'stash:version': { href: parent_version.self_path },
        'stash:files': { href: parent_version.files_path }
      }
      add_file_download!(hsh)
      add_download!(hsh)
      hsh
    end

    # secret internal link for admins only
    def add_file_download!(hsh)
      hsh['stash:file-download'] = { href: @se_data_file.s3_permanent_presigned_url } if @se_data_file.resource.submitted? &&
          @se_data_file.resource.admin_for_this_item?(user: @user)
    end

    def add_download!(hsh)
      hsh['stash:download'] = { href: api_url_helper.download_file_path(@se_data_file.id) } if @se_data_file.resource.submitted? &&
          @se_data_file.resource.may_download?(ui_user: @user)
    end

  end
end
