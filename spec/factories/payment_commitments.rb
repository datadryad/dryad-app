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
#  ldf_carryover        :float(24)
#  ldf_commitment       :float(24)
#  ldf_size_limit       :integer
#  payment_plan         :string(191)
#  period_discount      :float(24)
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
    payment_configuration_id { 1 }
    commitment_years { 1 }
    year { 'MyString' }
    integer { 'MyString' }
    payment_plan { 'MyString' }
    dpc_commitment { 1.5 }
    dpc_carriover { 1.5 }
    ldf_commitment { 1.5 }
    fdl_carryover { 1.5 }
    asf { 1.5 }
    period_discount { 1.5 }
    consortium_discount { 1.5 }
    asf_due { 1.5 }
    asf_prepayd { 1.5 }
  end
end
