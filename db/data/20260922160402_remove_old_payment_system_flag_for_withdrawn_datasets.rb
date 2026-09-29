# frozen_string_literal: true

class RemoveOldPaymentSystemFlagForWithdrawnDatasets < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Identifier.where(pub_state: :withdrawn, old_payment_system: true).update(old_payment_system: false)
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
