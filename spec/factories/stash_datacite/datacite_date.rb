FactoryBot.define do

  factory(:datacite_date, class: StashDatacite::DataciteDate) do
    date { '2018-11-14T01:04:02Z' }
    date_type { 'available' }
  end

end
