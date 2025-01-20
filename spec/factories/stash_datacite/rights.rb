# == Schema Information
#
# Table name: dcs_rights
#
#  id          :integer          not null, primary key
#  rights      :text(65535)
#  rights_uri  :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_dcs_rights_on_resource_id  (resource_id)
#
FactoryBot.define do

  factory :right, class: StashDatacite::Right do
    resource

    rights { 'Creative Commons Zero v1.0 Universal' }
    rights_uri { 'https://spdx.org/licenses/CC0-1.0.html' }
  end

end
