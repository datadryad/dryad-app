# == Schema Information
#
# Table name: sponsored_payment_logs
#
#  id           :bigint           not null, primary key
#  dpc          :integer
#  ldf          :integer
#  paid_storage :integer
#  payer_type   :string(191)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  payer_id     :string(191)
#  resource_id  :integer
#
# Indexes
#
#  index_sponsored_payment_logs_on_payer_id_and_payer_type  (payer_id,payer_type)
#
FactoryBot.define do

  factory :sponsored_payment_log do
    resource
    # payer

    id { Faker::Number.number }
    dpc { '1' }
    ldf { nil }
    payer_type { 'StashEngine::Tenant' }
    payer_id { 'dryad' }
  end

end
