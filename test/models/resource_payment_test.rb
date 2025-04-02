# == Schema Information
#
# Table name: resource_payments
#
#  id                  :bigint           not null, primary key
#  amount              :integer
#  payment_type        :string(191)
#  status              :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  checkout_session_id :string(191)
#  resource_id         :integer
#
# Indexes
#
#  index_resource_payments_on_checkout_session_id  (checkout_session_id)
#  index_resource_payments_on_resource_id          (resource_id)
#  index_resource_payments_on_status               (status)
#
require 'test_helper'

class ResourcePaymentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
