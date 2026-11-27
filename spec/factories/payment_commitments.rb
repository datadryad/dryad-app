# == Schema Information
#
# Table name: payment_commitments
#
#  id                   :bigint           not null, primary key
#  asf                  :float(24)
#  asf_due              :float(24)
#  asf_prepaid          :float(24)
#  batch                :string(191)
#  commitment_years     :integer
#  consortium_discount  :float(24)
#  covers_ldf           :boolean
#  deleted_at           :datetime
#  dpc_carryover        :integer
#  dpc_commitment       :integer
#  dpc_commitment_price :float(24)
#  dpc_tier             :integer
#  ldf_carryover        :float(24)
#  ldf_commitment       :float(24)
#  ldf_size_limit       :integer
#  payment_plan         :string(191)
#  period_discount      :float(24)
#  prepayment_carryover :float(24)
#  sponsor_type         :string(191)
#  start_date           :date
#  update_notes         :json
#  year                 :integer
#  year_index           :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  sponsor_id           :string(191)
#
# Indexes
#
#  index_payment_commitments_on_sponsor_id_and_sponsor_type  (sponsor_id,sponsor_type)
#
FactoryBot.define do
  factory :payment_commitment do
    commitment_years { 1 }
    year { 2026 }
    payment_plan { 'Annual' }
    dpc_commitment { 100.0 }
    dpc_carryover { 50.0 }
    dpc_tier { 1 }
    ldf_commitment { 200.0 }
    ldf_carryover { 100.0 }
    asf { 25.0 }
    period_discount { 10.0 }
    consortium_discount { 5.0 }
    asf_due { 150.0 }
    asf_prepaid { 75.0 }
    covers_ldf { true }
    batch { 'Batch1' }
    start_date { Date.new(2026, 1, 1) }
    update_notes { { note: 'Initial commitment' } }
    year_index { 1 }
    association :sponsor, factory: :journal_organization
    note { 'Initial commitment' }
  end
end
