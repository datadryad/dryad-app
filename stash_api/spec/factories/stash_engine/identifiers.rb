# see for setting up factorybot https://medium.com/@lukepierotti/setting-up-rspec-and-factory-bot-3bb2153fb909

FactoryBot.define do
  factory(:identifier, class: StashEngine::Identifier) do
    identifier { '138/238/2238' }
    identifier_type { 'DOI' }
  end
end
