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
