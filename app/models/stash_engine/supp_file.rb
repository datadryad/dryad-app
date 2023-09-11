module StashEngine
  class SuppFile < GenericFile

    def calc_s3_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      "#{resource.s3_dir_name(type: 'supplemental')}/#{upload_file_name}"
    end

    def public_zenodo_download_url
      copy = ZenodoCopy.where(resource_id: resource_id, copy_type: 'supp_publish').last
      return '#' if copy.nil? || copy.deposition_id.nil? || copy.state != 'finished' || file_state == 'deleted'

      "#{APP_CONFIG[:zenodo][:base_url]}/record/#{copy.deposition_id}/files/#{ERB::Util.url_encode(upload_file_name)}?download=1"
    end

    def zenodo_presigned_url
      rat = Stash::ZenodoSoftware::RemoteAccessToken.new(zenodo_config: APP_CONFIG.zenodo)
      dep_id = resource.zenodo_copies.supp&.last&.deposition_id
      raise "Zenodo presigned downloads must have deposition ids for resource #{resource.id}" if dep_id.blank?

      rat.magic_url(deposition_id: dep_id, filename: upload_file_name)
    end

    # the presigned URL for a file that was "directly" uploaded to Dryad,
    # rather than a file that was indicated by a URL reference
    def direct_s3_presigned_url
      Stash::Aws::S3.new.presigned_download_url(s3_key: "#{resource.s3_dir_name(type: 'supplemental')}/#{upload_file_name}")
    end

    # the URL we use for replication from other source (Presigned or URL) up to Zenodo
    def zenodo_replication_url
      if url.blank?
        direct_s3_presigned_url
      else
        url
      end
    end
  end
end
