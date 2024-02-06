# == Schema Information
#
# Table name: dcs_descriptions
#
#  id               :integer          not null, primary key
#  description      :text(16777215)
#  description_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  resource_id      :integer
#
# Indexes
#
#  index_dcs_descriptions_on_resource_id  (resource_id)
#
FactoryBot.define do

  factory :description, class: StashDatacite::Description do

    resource

    description_type { 'abstract' }
    description { Faker::Lorem.paragraph }

  end

end
