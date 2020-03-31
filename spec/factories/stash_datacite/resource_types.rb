FactoryBot.define do

  factory :resource_type, class: StashDatacite::ResourceType do
    resource

    resource_type_general { 'dataset' }
    resource_type { 'dataset' }
  end

end
