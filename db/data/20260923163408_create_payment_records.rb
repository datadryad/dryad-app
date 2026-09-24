# frozen_string_literal: true

class CreatePaymentRecords < ActiveRecord::Migration[8.0]
  def up
    # Sponsors and waivers
    StashEngine::Identifier.where.not(payment_type: ['stripe', 'unknown', nil]).each do |id|
      change_to = id.versions.find_by("JSON_EXTRACT(object_changes, '$.payment_id') like '[%\"#{id.payment_id}\"]'")
      res_id = change_to&.object&.[]('latest_resource_id') || id.latest_resource_id
      if id.payment_type == 'waiver'
        change_to = id.versions.find_by("JSON_EXTRACT(object_changes, '$.payment_type') like '[%\"waiver\"]'")
        res_id = change_to&.object&.[]('latest_resource_id') || id.latest_resource_id
        PaymentRecord.find_or_create_by(identifier: id, resource_id: res_id, payment_type: 'StashEngine::Waiver', payment_id: id.waiver_basis, fee_type: 'dpc', created_at: change_to&.created_at || id.latest_resource.created_at)
      elsif id.payment_type.start_with?('journal')
        journal = StashEngine::Journal.find_by_issn(id.payment_id)
        PaymentRecord.find_or_create_by(identifier: id, resource_id: res_id, payment: journal, payment_plan: id.payment_type.sub('journal-', ''), fee_type: 'dpc', created_at: change_to&.created_at || id.latest_resource.created_at)
      elsif id.payment_type.start_with?('institution')
        inst = StashEngine::Tenant.find_by(id: id.payment_id)
        PaymentRecord.find_or_create_by(identifier: id, resource_id: res_id, payment: inst, payment_plan: id.payment_type.sub('institution-', '').presence || '2025', fee_type: 'dpc', created_at: change_to&.created_at || id.latest_resource.created_at)
      elsif id.payment_type.start_with?('funder')
        PaymentRecord.find_or_create_by(identifier: id, resource_id: res_id, payment: StashEngine::Funder.first, fee_type: 'dpc', created_at: change_to&.created_at || id.latest_resource.created_at)
      end
    end
    # ResourcePayments
    ResourcePayment.paid.each do |payment|
      fee_type = if payment.ppr_fee_paid?
                  'ppr'
                 elsif payment.resource.identifier.payment_type != 'stripe'
                  'ldf'
                 else
                  'dpc'
                 end
      PaymentRecord.find_or_create_by(payment: payment, resource: payment.resource, identifier: payment.resource.identifier, fee_type: fee_type, created_at: payment.created_at)
    end
    ResourcePayment.refunded.each do |payment|
      PaymentRecord.find_or_create_by(payment: payment, resource: payment.resource, identifier: payment.resource.identifier, active: false, created_at: payment.created_at)
    end
    ResourcePayment.voided.each do |payment|
      PaymentRecord.find_or_create_by(payment: payment, resource: payment.resource, identifier: payment.resource.identifier, active: false, created_at: payment.created_at)
    end
    # SponsoredPaymentLogs
    SponsoredPaymentLog.all.each do |payment|
      PaymentRecord.find_or_create_by(payment: payment, resource: payment.resource, identifier: payment.resource.identifier, fee_type: 'ldf', created_at: payment.created_at)
    end
    # History (excluding ResourcePayments)
    StashEngine::Identifier.joins(:versions).where("payment_type IS NOT NULL and (JSON_EXTRACT(object_changes, '$.payment_id') IS NOT NULL or JSON_EXTRACT(object_changes, '$.waiver_basis') IS NOT NULL) and JSON_EXTRACT(object_changes, '$.payment_id') not like CONCAT('[%\"', payment_id, '\"]')").distinct.each do |id|
      id.versions.where("(JSON_EXTRACT(object_changes, '$.payment_id') IS NOT NULL or JSON_EXTRACT(object_changes, '$.waiver_basis') IS NOT NULL) and JSON_EXTRACT(object_changes, '$.payment_id') not like '[%\"#{id.payment_id}\"]'").each do |log|
        pay_id = log.object_changes.dig('payment_id', 1)  
        type = log.object_changes.dig('payment_type', 1).presence || log.object['payment_type']
        next if pay_id.nil?
        next if type.blank? || ['stripe', 'unknown'].include?(type)

        payment = case type
          when 'waiver'
            OpenStruct.new(
              class: OpenStruct.new(name: 'StashEngine::Waiver'),
              id: log.object_changes.dig('waiver_basis', 1).presence || log.object['waiver_basis']
            )
          when /^institution/
            StashEngine::Tenant.find_by(id: pay_id)
          when /^journal/
            StashEngine::Journal.find_by_issn(pay_id)
          when /^funder/
            StashEngine::Funder.first
          else
            nil
          end
        next if payment.blank?

        rec = PaymentRecord.find_or_create_by(payment_type: payment.class.name, payment_id: payment.id, resource_id: log.object['latest_resource_id'], identifier: id, fee_type: 'dpc',  payment_plan: type.partition('-').last.presence || '2025', active: false)
        rec.update_columns(created_at: log.created_at)
      end
    end
  end

  def down
    PaymentRecord.dpc.active.each do |r|    
      next if r.payment_type == 'SponsoredPaymentLog'

      type = if r.payment_type == 'ResourcePayment'
        'stripe'
      else
        r.payment_type.parameterize.sub('stashengine-', '').sub('tenant', 'institution')
      end
      type += "-#{r.payment_plan}" if r.payment_plan
      id = case r.payment_type
        when 'ResourcePayment'
          r.payment.payment_intent.presence || r.payment.invoice_id
        when 'StashEngine::Funder'
          "funder:#{r.payment.name}"
        when 'StashEngine::Tenant'
          r.payment.id
        when 'StashEngine::Journal'
          r.payment.single_issn
        when 'StashEngine::Waiver'
          nil
        end
      r.identifier.update(payment_type: type, payment_id: id, waiver_basis: r.payment_type == 'StashEngine::Waiver' ? r.payment_id : nil)
    end
  end
end
