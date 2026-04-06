# == Schema Information
#
# Table name: sponsored_payment_logs
#
#  id          :bigint           not null, primary key
#  deleted_at  :datetime
#  dpc         :integer
#  ldf         :integer
#  payer_type  :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  payer_id    :string(191)
#  resource_id :integer
#  sponsor_id  :string(191)
#
# Indexes
#
#  index_sponsored_payment_logs_on_deleted_at               (deleted_at)
#  index_sponsored_payment_logs_on_payer_id_and_payer_type  (payer_id,payer_type)
#  index_sponsored_payment_logs_on_sponsor_id               (sponsor_id)
#
FactoryBot.define do

  factory :sponsored_payment_log do
    resource

    id { Faker::Number.number }
    dpc { '1' }
    ldf { nil }
    payer_type { 'StashEngine::Tenant' }
    payer_id { 'dryad' }
    deleted_at { nil }
  end
end
