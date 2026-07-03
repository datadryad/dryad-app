# frozen_string_literal: true

class FixOldFeeModelDatasets < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.transaction do
      # deleting all logs with LDF = 0
      SponsoredPaymentLog.where(ldf: 0).destroy_all

      logs = StashEngine::Identifier.joins(:process_date, :sponsored_payment_logs)
        .select('LEAST(processing, queued, peer_review) as first_sub_date, stash_engine_identifiers.id, ldf')
        .having('first_sub_date < ?', '2026-01-01'.to_datetime)

      puts 'Deleting logs with following info:'
      puts 'Identifier ID, First Submission Date, LDF'
      pp logs.map{|a| [a.id, a.first_sub_date, a.ldf]}
      SponsoredPaymentLog.joins(resource: :identifier).where(identifier:{ id: logs.ids }).destroy_all
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
