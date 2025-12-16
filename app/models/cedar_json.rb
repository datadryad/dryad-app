# == Schema Information
#
# Table name: cedar_json
#
#  id          :bigint           not null, primary key
#  json        :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#  template_id :string(191)
#
# Indexes
#
#  index_cedar_json_on_resource_id  (resource_id)
#  index_cedar_json_on_template_id  (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (resource_id => stash_engine_resources.id)
#  fk_rails_...  (template_id => cedar_templates.id)
#
class CedarJson < ApplicationRecord
  self.table_name = :cedar_json

  belongs_to :resource, class_name: 'StashEngine::Resource'
  belongs_to :cedar_template, foreign_key: :template_id
end
