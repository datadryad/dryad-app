# == Schema Information
#
# Table name: stash_engine_container_files
#
#  id           :bigint           not null, primary key
#  mime_type    :string(191)
#  path         :text(65535)
#  size         :bigint
#  data_file_id :bigint
#
# Indexes
#
#  index_stash_engine_container_files_on_data_file_id  (data_file_id)
#  index_stash_engine_container_files_on_mime_type     (mime_type)
#
module StashEngine
  class ContainerFile < ApplicationRecord
    self.table_name = 'stash_engine_container_files'
    belongs_to :data_file, class_name: 'StashEngine::DataFile'
  end
end
