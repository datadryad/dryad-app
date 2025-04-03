# frozen_string_literal: true

class PopulateOldPaymentSystemFlag < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Identifier.where(
      publication_date: nil,
      payment_id: nil
    ).where.not(pub_state: 'withdrawn')
      .where.not(import_info: 'published')
      .where.not(payment_type: 'waiver')
      .joins(:latest_resource)
      .where(stash_engine_resources: { accepted_agreement: true })
      .update_all(old_payment_system: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
