# == Schema Information
#
# Table name: stash_engine_versions
#
#  id              :integer          not null, primary key
#  version         :integer
#  zip_filename    :text(65535)
#  resource_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  merritt_version :integer
#
module StashEngine
  class Version < ApplicationRecord
    self.table_name = 'stash_engine_versions'
    belongs_to :resource, class_name: 'StashEngine::Resource'
  end
end
