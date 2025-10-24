# frozen_string_literal: true

class AddIdentifierStripePaymentInfo < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Identifier.where(payment_type: [nil, 'unknown']).each do |identifier|
      next if identifier.payments.paid.blank?

      identifier.update(
        payment_type: 'stripe',
        payment_id:   identifier.payments.paid.order(created_at: :desc).first.payment_id
      )
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
