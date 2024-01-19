# == Schema Information
#
# Table name: stash_engine_funder_roles
#
#  id          :bigint           not null, primary key
#  user_id     :bigint
#  funder_id   :string(191)
#  funder_name :string(191)
#  role        :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do

  factory :funder_role, class: StashEngine::FunderRole do

    user
    funder_id { "#{Faker::Name.initials(number: 4)}-#{Faker::Number.number(digits: 4)}" }
    funder_name { Faker::Company.name }
    role { 'admin' }

  end

end
