# frozen_string_literal: true

class FixOldFeeModelDatasets < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.transaction do
      # deleting all logs with LDF = 0
      SponsoredPaymentLog.where(ldf: 0).destroy_all

      puts 'Deleting logs with following info:'
      puts 'Identifier ID, First Submission Date, LDF'

      logs = StashEngine::Identifier.joins(:process_date, :sponsored_payment_logs)
        .select('COALESCE(processing, queued, peer_review) as first_sub_date, stash_engine_identifiers.id, ldf')
        .having('first_sub_date < ?', '2026-01-01'.to_datetime)
        .where.not(id: [125313, 111580])

      logs.each do |item|
        payer = StashEngine::Identifier.find(item.id).payer
        next unless payer.is_a?(StashEngine::Tenant)

        pp [item.id, item.first_sub_date, item.ldf]
        SponsoredPaymentLog.joins(resource: :identifier).where(identifier:{ id: item.id }).destroy_all
      end
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
