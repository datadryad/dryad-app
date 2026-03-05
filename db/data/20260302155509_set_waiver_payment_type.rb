# frozen_string_literal: true

class SetWaiverPaymentType < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Identifier.where(payment_type: 'stripe').where.not(waiver_basis: 'waiver').update_all(payment_type: 'waiver')
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
