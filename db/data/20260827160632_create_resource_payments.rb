# frozen_string_literal: true

class CreateResourcePayments < ActiveRecord::Migration[8.0]
  def up
    # create resource payments records for old invoices
    StashEngine::Identifier.where("stash_engine_identifiers.payment_type = 'stripe'").where.missing(:payments).distinct.each do |id|
      res = id.resources.with_public_metadata.first
      payment = ResourcePayment.create(
        resource_id: res.id,
        payment_type: id.payment_type,
        pay_with_invoice: true,
        invoice_id: id.payment_id,
        created_at: res.first_published_status.created_at
      )
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
