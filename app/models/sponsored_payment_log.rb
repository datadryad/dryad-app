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
#  payer_id     :integer
#  resource_id  :integer
#
class SponsoredPaymentLog < ApplicationRecord

  belongs_to :payer, polymorphic: true
  belongs_to :resource, class_name: StashEngine::Resource.to_s

  validates :resource_id, presence: true
  validates :payer_id, presence: true
  validates :payer_type, presence: true
  validates :paid_storage, presence: true

end
