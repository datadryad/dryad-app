# == Schema Information
#
# Table name: stash_engine_container_files
#
#  id           :bigint           not null, primary key
#  data_file_id :bigint
#  path         :text(65535)
#  mime_type    :string(191)
#  size         :bigint
#
module StashEngine
  class ContainerFile < ApplicationRecord
    self.table_name = 'stash_engine_container_files'
    belongs_to :data_file, class_name: 'StashEngine::DataFile'
  end
end
