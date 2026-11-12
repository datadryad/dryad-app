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
#  id                       :bigint           not null, primary key
#  asf                      :float(24)
#  asf_due                  :float(24)
#  asf_prepaid              :float(24)
#  commitment_years         :integer
#  consortium_discount      :float(24)
#  deleted_at               :datetime
#  dpc_carryover            :float(24)
#  dpc_commitment           :float(24)
#  fdl_carryover            :float(24)
#  ldf_commitment           :float(24)
#  payment_plan             :string(191)
#  period_discount          :float(24)
#  update_notes             :json
#  year                     :integer
#  year_index               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  payment_configuration_id :integer

class PaymentCommitment < ApplicationRecord
  attr_accessor :note
  acts_as_paranoid
  has_paper_trail

  belongs_to :payment_configuration

  validates_presence_of :note

  before_save :set_note

  def set_note
    self.update_notes = (update_notes || {}).merge({ Time.current.to_s => note })
  end
end
