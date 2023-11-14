FactoryBot.define do

  factory :external_dependency, class: StashEngine::ExternalDependency do
    abbreviation { 'solr' }
    name { 'Solr' }
    description { 'The Solr engine that drives the Dryad "Explore data" pages' }
    documentation { 'Solr drives the logic behind the \'Explore data\' section of the application.' }
    internally_managed { true }
    status { 1 }

  end
end
