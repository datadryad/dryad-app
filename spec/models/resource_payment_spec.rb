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
module StashEngine

  describe ResourcePayment, type: :model do

    describe '#destroy' do
      it_should_behave_like 'soft delete record', :resource_payment
    end
  end
end
