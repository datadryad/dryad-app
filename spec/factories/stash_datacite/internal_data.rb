FactoryBot.define do

  factory(:internal_data, class: StashEngine::InternalDatum) do
    data_type { 'publicationName' }
    value { 'Journal of Testing Fun' }
  end

end
