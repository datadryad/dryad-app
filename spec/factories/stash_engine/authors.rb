FactoryBot.define do

  factory :author, class: StashEngine::Author do

    resource

    author_first_name { Faker::Name.unique.first_name }
    author_last_name { Faker::Name.unique.last_name }
    author_email { Faker::Internet.unique.safe_email }
    author_orcid { Faker::Pid.unique.orcid }

    before(:create) do |author|
      author.affiliations << create(:affiliation)
    end

  end

end
