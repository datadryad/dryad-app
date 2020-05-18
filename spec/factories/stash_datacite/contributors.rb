FactoryBot.define do

  factory :contributor, class: StashDatacite::Contributor do

    resource

    contributor_name    { Faker::Company.name }
    contributor_type    { 'funder' }
    name_identifier_id  { Faker::Pid.doi }
    award_number        { Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4) }
  end

end
