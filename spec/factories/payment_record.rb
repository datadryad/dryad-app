# == Schema Information
#
# Table name: payment_records
#
#  id            :bigint           not null, primary key
#  active        :boolean          default(TRUE)
#  fee_type      :string(191)      default("dpc")
#  payment_plan  :string(191)
#  payment_type  :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :bigint
#  payment_id    :string(191)
#  resource_id   :bigint
#
# Indexes
#
#  index_payment_records_on_identifier_id_and_fee_type   (identifier_id,fee_type)
#  index_payment_records_on_payment_type_and_payment_id  (payment_type,payment_id)
#  index_payment_records_on_resource_id_and_fee_type     (resource_id,fee_type)
#
FactoryBot.define do

  factory :payment_record do
    identifier
    resource

    payment { create(:resource_payment) }
    payment_plan { '2025' }
    fee_type { 'dpc' }
    active { true }
  end
end
