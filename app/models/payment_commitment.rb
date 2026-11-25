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
class PaymentCommitment < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  attr_accessor :note
  attr_writer :dpc_tier

  belongs_to :sponsor, polymorphic: true

  validates_presence_of :note
  validates_uniqueness_of :year, scope: :sponsor, conditions: -> { where(deleted_at: nil) }
  after_validation :validate_dpc_tier

  before_save :set_note

  def dpc_tier
    return ESTIMATED_DATASETS.map { |a| a[:tier].to_i }.first if dpc_commitment_price.blank?

    tier = ESTIMATED_DATASETS.find { |tier| tier[:price] == dpc_commitment_price }
    tier[:tier]
  end

  def set_note
    self.update_notes = (update_notes || {}).merge({ Time.current.to_s => note })
  end

  def validate_dpc_tier
    return true if ESTIMATED_DATASETS.map { |a| a[:tier].to_i == dpc_tier.to_i }

    errors.add(:dpc_tier, 'is invalid')
  end
end
