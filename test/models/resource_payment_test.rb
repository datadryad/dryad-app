# == Schema Information
#
# Table name: resource_payments
#
#  id                          :bigint           not null, primary key
#  amount                      :integer
#  invoice_details             :json
#  paid_at                     :datetime
#  pay_with_invoice            :boolean          default(FALSE)
#  payment_email               :string(191)
#  payment_intent              :string(191)
#  payment_status              :string(191)
#  payment_type                :string(191)
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
#  index_resource_payments_on_paid_at              (paid_at)
#  index_resource_payments_on_resource_id          (resource_id)
#  index_resource_payments_on_status               (status)
#
require 'test_helper'

class ResourcePaymentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
