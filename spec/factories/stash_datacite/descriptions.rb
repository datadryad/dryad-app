# == Schema Information
#
# Table name: dcs_descriptions
#
#  id               :integer          not null, primary key
#  description      :text(16777215)
#  description_type :string
#  resource_id      :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do

  factory :description, class: StashDatacite::Description do

    resource

    description_type { 'abstract' }
    description { Faker::Lorem.paragraph }

  end

end
