# == Schema Information
#
# Table name: payment_configurations
#
#  id                   :bigint           not null, primary key
#  covers_dpc           :boolean
#  covers_ldf           :boolean
#  ldf_limit            :integer
#  partner_type         :string(191)
#  payment_plan         :integer
#  yearly_ldf_fee_limit :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  partner_id           :string(191)
#
FactoryBot.define do

  factory :payment_configuration do
    id { Faker::Number.number }
    partner { '1' }
    payment_plan { nil }
    covers_dpc { nil }
    covers_ldf { nil }
    ldf_limit { nil }
    yearly_ldf_fee_limit { nil }

    to_create do |instance|
      record = PaymentConfiguration.find_or_initialize_by(partner: instance.partner)
      record.update(instance.attributes.compact)
    end
  end

end
