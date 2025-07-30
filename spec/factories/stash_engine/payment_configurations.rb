# == Schema Information
#
# Table name: payment_configurations
#
#  id           :bigint           not null, primary key
#  covers_dpc   :boolean
#  covers_ldf   :boolean
#  ldf_limit    :integer
#  partner_type :string(191)
#  payment_plan :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  partner_id   :string(191)
#
FactoryBot.define do

  factory :payment_configuration do
    id { Faker::Number.number }
  end

end
