# == Schema Information
#
# Table name: cedar_word_banks
#
#  id         :bigint           not null, primary key
#  keywords   :text(65535)
#  label      :string(191)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do

  factory :cedar_word_bank do
    label { Faker::Lorem.sentence }
    keywords { 5.times.map { Faker::Lorem.word }.join('|') }
  end
end
