# == Schema Information
#
# Table name: dcs_resource_types
#
#  id                    :integer          not null, primary key
#  resource_type_general :string
#  resource_type         :text(65535)
#  resource_id           :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
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
