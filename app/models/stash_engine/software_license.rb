# == Schema Information
#
# Table name: stash_engine_software_licenses
#
#  id          :integer          not null, primary key
#  name        :string(191)
#  identifier  :string(191)
#  details_url :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashEngine
  class SoftwareLicense < ActiveRecord::Base
    self.table_name = 'stash_engine_software_licenses'
    has_many :dataset_identifiers, class_name: 'StashEngine::Identifier'

  end
end
