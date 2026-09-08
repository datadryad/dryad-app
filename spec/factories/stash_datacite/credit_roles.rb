# == Schema Information
#
# Table name: dcs_credit_roles
#
#  id               :bigint           not null, primary key
#  contributor_type :string(191)
#  credit_role      :string(191)
#  description      :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  credit_id        :string(191)
#
FactoryBot.define do

  factory :credit_role, class: StashDatacite::CreditRole do
    contributor_type { %w[projectleader datacurator datacollector researcher projectmanager supervisor editor].sample }
    credit_role { Faker::Hobby.activity }
    credit_id { Faker::Internet.uuid }
  end

end
