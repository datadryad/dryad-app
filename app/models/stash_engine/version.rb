# == Schema Information
#
# Table name: stash_engine_versions
#
#  id              :integer          not null, primary key
#  deleted_at      :datetime
#  merritt_version :integer
#  version         :integer
#  zip_filename    :text(65535)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  resource_id     :integer
#
# Indexes
#
#  index_stash_engine_versions_on_deleted_at   (deleted_at)
#  index_stash_engine_versions_on_resource_id  (resource_id)
#
module StashEngine
  class Version < ApplicationRecord
    self.table_name = 'stash_engine_versions'
    acts_as_paranoid

    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
