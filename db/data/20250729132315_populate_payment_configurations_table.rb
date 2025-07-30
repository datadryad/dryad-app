# frozen_string_literal: true

class PopulatePaymentConfigurationsTable < ActiveRecord::Migration[8.0]
  def up
    StashEngine::Tenant.all.each do |tenant|
      next if tenant.payment_configuration

      record = tenant.build_payment_configuration(
        payment_plan: tenant.read_attribute(:payment_plan),
        covers_dpc: tenant.read_attribute(:covers_dpc),
        covers_ldf: tenant.read_attribute(:covers_ldf)
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
        payment_plan: funder.read_attribute(:payment_plan),
        covers_dpc: funder.read_attribute(:covers_dpc),
        covers_ldf: funder.read_attribute(:covers_ldf)
      )
      record.save!
    end
  end

  def down
    PaymentConfiguration.delete_all
    # raise ActiveRecord::IrreversibleMigration
  end
end
