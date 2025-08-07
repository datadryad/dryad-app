# == Schema Information
#
# Table name: resource_payments
#
#  id                          :bigint           not null, primary key
#  amount                      :integer
#  deleted_at                  :datetime
#  has_discount                :boolean          default(FALSE)
#  invoice_details             :json
#  paid_at                     :datetime
#  pay_with_invoice            :boolean          default(FALSE)
#  payment_email               :string(191)
#  payment_intent              :string(191)
#  payment_status              :string(191)
#  payment_type                :string(191)
#  ppr_fee_paid                :boolean          default(FALSE)
#  status                      :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  checkout_session_id         :string(191)
#  invoice_id                  :string(191)
#  payment_checkout_session_id :string(191)
#  resource_id                 :integer
#
# Indexes
#
#  index_resource_payments_on_checkout_session_id  (checkout_session_id)
#  index_resource_payments_on_deleted_at           (deleted_at)
#  index_resource_payments_on_paid_at              (paid_at)
#  index_resource_payments_on_resource_id          (resource_id)
#  index_resource_payments_on_status               (status)
#
class ResourcePayment < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :resource, class_name: 'StashEngine::Resource'

  enum :status, { created: 1, paid: 2, failed: 3 }

  scope :with_discount, -> { where(has_discount: true) }
  scope :ppr_paid, -> { where(ppr_fee_paid: true) }

  def void_invoice
    rails 'Payment is not an invoice' unless pay_with_invoice

    Stripe.api_key     = APP_CONFIG.payments.key
    Stripe.api_version = '2025-03-31.basil'
    Stripe::Invoice.void_invoice(invoice_id)
  end
end
