# == Schema Information
#
# Table name: payment_configurations
#
#  id           :bigint           not null, primary key
#  covers_dpc   :boolean
#  covers_ldf   :boolean
#  ldf_limit    :integer
#  partner_type :string(191)
#  payment_plan :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  partner_id   :string(191)
#

# NOTE: ldf_limit stores the tier number and not an actual limit size
class PaymentConfiguration < ApplicationRecord
  has_paper_trail

  belongs_to :partner, polymorphic: true, optional: true

  enum :payment_plan, { SUBSCRIPTION: 1, PREPAID: 2, DEFERRED: 3, TIERED: 4, '2025': 5 }
  before_save :reset_limit

  private

  def reset_limit
    self.ldf_limit = nil unless covers_ldf
  end
end
