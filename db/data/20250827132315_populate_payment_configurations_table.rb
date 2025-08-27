# frozen_string_literal: true

class PopulatePaymentConfigurationsTable < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Tenant.all.each do |tenant|
      next if tenant.payment_configuration

      record = tenant.build_payment_configuration(
        payment_plan: parse_payment_plan(tenant),
        covers_dpc: tenant.old_covers_dpc,
        covers_ldf: tenant.old_covers_ldf
      )
      record.save!
    end

    StashEngine::Journal.all.each do |journal|
      next if journal.payment_configuration

      record = journal.build_payment_configuration(
        payment_plan: journal.old_payment_plan_type,
        covers_dpc: StashEngine::Journal::PAYMENT_PLANS.include?(journal.old_payment_plan_type),
        covers_ldf: journal.old_covers_ldf
      )
      record.save!
    end


    StashEngine::Funder.where.not(old_payment_plan: nil).each do |funder|
      next if funder.payment_configuration

      record = funder.build_payment_configuration(
        payment_plan: parse_payment_plan(funder),
        covers_dpc: funder.old_covers_dpc,
        covers_ldf: funder.old_covers_ldf
      )
      record.save!
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end

  def parse_payment_plan(record)
    return 'TIERED' if record.old_payment_plan == 0
    return '2025' if record.old_payment_plan == 1
    return 'SUBSCRIPTION' if record.old_payment_plan.nil? && record.old_covers_dpc

    record.old_payment_plan
  end
end
