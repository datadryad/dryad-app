# frozen_string_literal: true

class PopulatePaymentConfigurationsTable < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Tenant.all.each do |tenant|
      next if tenant.payment_configuration

      record = tenant.build_payment_configuration(
        payment_plan: parse_payment_plan(tenant),
        covers_dpc: tenant.covers_dpc,
        covers_ldf: tenant.covers_ldf
      )
      record.save!
    end

    StashEngine::Journal.all.each do |journal|
      next if journal.payment_configuration

      record = journal.build_payment_configuration(
        payment_plan: journal.read_attribute(:payment_plan_type),
        covers_dpc: journal.will_pay?,
        covers_ldf: journal.read_attribute(:covers_ldf)
      )
      record.save!
    end


    StashEngine::Funder.where.not(payment_plan: nil).each do |funder|
      next if funder.payment_configuration

      record = funder.build_payment_configuration(
        payment_plan: parse_payment_plan(funder),
        covers_dpc: funder.covers_dpc,
        covers_ldf: funder.covers_ldf
      )
      record.save!
    end
  end

  def down
    # PaymentConfiguration.delete_all
    raise ActiveRecord::IrreversibleMigration
  end

  def parse_payment_plan(record)
    return 'TIERED' if record.payment_plan == 0
    return '2025' if record.payment_plan == 1
    return 'SUBSCRIPTION' if record.payment_plan.nil? && record.covers_dpc

    record.payment_plan
  end
end
