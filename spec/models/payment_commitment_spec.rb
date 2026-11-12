# == Schema Information
#
# Table name: payment_commitments
#
#  id                       :bigint           not null, primary key
#  asf                      :float(24)
#  asf_due                  :float(24)
#  asf_prepaid              :float(24)
#  batch                    :string(191)
#  commitment_years         :integer
#  consortium_discount      :float(24)
#  deleted_at               :datetime
#  dpc_carryover            :float(24)
#  dpc_commitment           :float(24)
#  ldf_carryover            :float(24)
#  ldf_commitment           :float(24)
#  payment_plan             :string(191)
#  period_discount          :float(24)
#  start_date               :date
#  update_notes             :json
#  year                     :integer
#  year_index               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  payment_configuration_id :integer
#
describe PaymentCommitment, type: :model do
  describe '#destroy' do
    it_should_behave_like 'soft delete record', :payment_commitment
  end
end
