module StashEngine
  class SoftwareUpload < FileUpload
    self.table_name = 'stash_engine_software_uploads'

    undef_method :download_histories, :version_file_created_in, :merritt_url, :merritt_presign_info_url,
                 :s3_presigned_url, :merritt_express_url

    def calc_file_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      # the uploads directory is well defined so we can calculate it and don't need to store it
      File.join(Resource.software_upload_dir_for(resource_id), upload_file_name).to_s
    end

  end
end
