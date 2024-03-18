# == Schema Information
#
# Table name: dcs_resource_types
#
#  id                    :integer          not null, primary key
#  resource_type         :text(65535)
#  resource_type_general :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  resource_id           :integer
#
# Indexes
#
#  index_dcs_resource_types_on_resource_id  (resource_id)
#
FactoryBot.define do

  factory :resource_type, class: StashDatacite::ResourceType do
    resource

    resource_type_general { 'dataset' }
    resource_type { 'dataset' }
  end

  factory :resource_type_collection, class: StashDatacite::ResourceType do
    resource

    resource_type_general { 'collection' }
    resource_type { 'collection' }
  end

end
