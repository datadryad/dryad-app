FactoryBot.define do

  factory :author, class: StashEngine::Author do
    resource

    author_first_name { Faker::Name.first_name }
    author_last_name { Faker::Name.last_name }
    author_email { Faker::Internet.email }
    author_orcid { Faker::Pid.orcid }
    affiliations { [create(:affiliation)] }
  end

end
