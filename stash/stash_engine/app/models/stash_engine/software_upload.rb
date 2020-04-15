module StashEngine
  class SoftwareUpload < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    # undef_method :download_histories, :version_file_created_in, :merritt_url, :merritt_presign_info_url,
    #              :s3_presign_url, :merritt_express_url

    # seems like most methods are OK to have, but probably need to be overridden
    # calc_file_path

  end
end
