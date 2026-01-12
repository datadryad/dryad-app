# == Schema Information
#
# Table name: sponsored_payment_logs
#
#  id          :bigint           not null, primary key
#  dpc         :integer
#  ldf         :integer
#  payer_type  :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  payer_id    :string(191)
#  resource_id :integer
#
# Indexes
#
#  index_sponsored_payment_logs_on_payer_id_and_payer_type  (payer_id,payer_type)
#
class SponsoredPaymentLog < ApplicationRecord

  belongs_to :payer, polymorphic: true
  belongs_to :resource, class_name: StashEngine::Resource.to_s

  validates :resource_id, presence: true
  validates :payer_id, presence: true
  validates :payer_type, presence: true
  validates :ldf, presence: true

  scope :for_current_year, -> { where('year(created_at) = ?', Date.today.year) }

end
