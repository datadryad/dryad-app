# == Schema Information
#
# Table name: payment_configurations
#
#  id                     :bigint           not null, primary key
#  covers_dpc             :boolean
#  covers_ldf             :boolean
#  ldf_limit              :integer
#  ldf_limit_notification :text(65535)
#  partner_type           :string(191)
#  payment_plan           :integer
#  yearly_ldf_limit       :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  partner_id             :string(191)
#

# NOTE: ldf_limit stores the tier number and not an actual limit size
class PaymentConfiguration < ApplicationRecord
  has_paper_trail
  validate :email_array

  belongs_to :partner, polymorphic: true, optional: true

  enum :payment_plan, { SUBSCRIPTION: 1, PREPAID: 2, DEFERRED: 3, TIERED: 4, '2025': 5 }
  before_save :reset_limit, :set_covers_dpc
  before_validation :notification_json

  def valid_payer?
    covers_dpc? && payment_plan.present?
  end

  def ldf_limit_notification
    JSON.parse(super) unless super.nil?
  rescue JSON::ParserError
    super
  end

  def email_array
    ldf_limit_notification&.each do |email|
      errors.add(:ldf_limit_notification, "#{email} is not a valid email address") unless email.match?(EMAIL_REGEX)
    end
  end

  private

  def notification_json
    self.ldf_limit_notification = ldf_limit_notification.to_s.split("\n").map(&:strip).to_json
  end

  def reset_limit
    return if covers_ldf

    self.ldf_limit = nil
    self.yearly_ldf_limit = nil
  end

  def set_covers_dpc
    return unless covers_dpc.nil?

    self.covers_dpc = payment_plan.present?
  end
end
