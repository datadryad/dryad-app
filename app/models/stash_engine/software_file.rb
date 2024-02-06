# == Schema Information
#
# Table name: stash_engine_generic_files
#
#  id                  :integer          not null, primary key
#  cloud_service       :string(191)
#  compressed_try      :integer          default(0)
#  description         :text(65535)
#  digest              :string(191)
#  digest_type         :string(8)
#  file_state          :string(7)
#  original_filename   :text(65535)
#  original_url        :text(65535)
#  status_code         :integer
#  timed_out           :boolean          default(FALSE)
#  type                :string(191)
#  upload_content_type :text(65535)
#  upload_file_name    :text(65535)
#  upload_file_size    :bigint
#  upload_updated_at   :datetime
#  url                 :text(65535)
#  validated_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  resource_id         :integer
#  storage_version_id  :integer
#
# Indexes
#
#  index_stash_engine_generic_files_on_file_state        (file_state)
#  index_stash_engine_generic_files_on_resource_id       (resource_id)
#  index_stash_engine_generic_files_on_upload_file_name  (upload_file_name)
#  index_stash_engine_generic_files_on_url               (url)
#
module StashEngine
  class SoftwareFile < GenericFile

    def s3_staged_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      "#{resource.s3_dir_name(type: 'software')}/#{upload_file_name}"
    end

    def public_zenodo_download_url
      copy = ZenodoCopy.where(resource_id: resource_id, copy_type: 'software_publish').last
      return '#' if copy.nil? || copy.deposition_id.nil? || copy.state != 'finished' || file_state == 'deleted'

      "#{APP_CONFIG[:zenodo][:base_url]}/record/#{copy.deposition_id}/files/#{ERB::Util.url_encode(upload_file_name)}?download=1"
    end

    def zenodo_presigned_url
      rat = Stash::ZenodoSoftware::RemoteAccessToken.new(zenodo_config: APP_CONFIG.zenodo)
      dep_id = resource.zenodo_copies.software&.last&.deposition_id
      raise "Zenodo presigned downloads must have deposition ids for resource #{resource.id}" if dep_id.blank?

      rat.magic_url(deposition_id: dep_id, filename: upload_file_name)
    end

    # the presigned URL for a file that was "directly" uploaded to Dryad,
    # rather than a file that was indicated by a URL reference
    def s3_staged_presigned_url
      Stash::Aws::S3.new.presigned_download_url(s3_key: "#{resource.s3_dir_name(type: 'software')}/#{upload_file_name}")
    end

    # the URL we use for replication from other source (Presigned or URL) up to Zenodo
    def zenodo_replication_url
      if url.blank?
        s3_staged_presigned_url
      else
        url
      end
    end

  end
end
