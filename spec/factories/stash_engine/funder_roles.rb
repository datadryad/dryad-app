# == Schema Information
#
# Table name: stash_engine_funder_roles
#
#  id          :bigint           not null, primary key
#  funder_name :string(191)
#  role        :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  funder_id   :string(191)
#  user_id     :bigint
#
# Indexes
#
#  index_stash_engine_funder_roles_on_user_id  (user_id)
#
FactoryBot.define do

  factory :funder_role, class: StashEngine::FunderRole do

    user
    funder_id { "#{Faker::Name.initials(number: 4)}-#{Faker::Number.number(digits: 4)}" }
    funder_name { Faker::Company.name }
    role { 'admin' }

  end

end
