# == Schema Information
#
# Table name: payment_records
#
#  id            :bigint           not null, primary key
#  active        :boolean          default(TRUE)
#  fee_type      :string(191)      default("dpc")
#  payment_plan  :string(191)
#  payment_type  :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :bigint
#  payment_id    :string(191)
#  resource_id   :bigint
#
# Indexes
#
#  index_payment_records_on_identifier_id_and_fee_type   (identifier_id,fee_type)
#  index_payment_records_on_payment_type_and_payment_id  (payment_type,payment_id)
#  index_payment_records_on_resource_id_and_fee_type     (resource_id,fee_type)
#
class PaymentRecord < ApplicationRecord
  belongs_to :payment, polymorphic: true, optional: true
  belongs_to :identifier, class_name: 'StashEngine::Identifier'
  belongs_to :resource, class_name: 'StashEngine::Resource'
  belongs_to :tenant, -> {
    where(payment_records: { payment_type: 'StashEngine::Tenant' }).includes(:payment_records)
  }, class_name: 'StashEngine::Tenant', foreign_key: 'payment_id', optional: true
  belongs_to :journal, -> {
    where(payment_records: { payment_type: 'StashEngine::Journal' }).includes(:payment_records)
  }, class_name: 'StashEngine::Journal', foreign_key: 'payment_id', optional: true
  belongs_to :funder, -> {
    where(payment_records: { payment_type: 'StashEngine::Funder' }).includes(:payment_records)
  }, class_name: 'StashEngine::Funder', foreign_key: 'payment_id', optional: true
  belongs_to :resource_payment, -> {
    where(payment_records: { payment_type: 'ResourcePayment' }).includes(:payment_records)
  }, foreign_key: 'payment_id', optional: true
  belongs_to :payment_log, -> {
    where(payment_records: { payment_type: 'SponsoredPaymentLog' }).includes(:payment_records)
  }, class_name: 'SponsoredPaymentLog', foreign_key: 'payment_id', optional: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  vals = %w[ppr dpc ldf]
  enum :fee_type, vals.index_by(&:to_sym), default: 'dpc', validate: true

  def payment
    return nil if payment_type == 'StashEngine::Waiver'

    super
  end

  def readable_type
    return 'stripe' if payment_type == 'ResourcePayment'

    type = payment_type == 'SponsoredPaymentLog' ? payment.payer_type : payment_type
    type.parameterize.sub('stashengine-', '').sub('tenant', 'institution')
  end

  def link
    return nil if payment_type == 'StashEngine::Waiver'

    if payment_type == 'ResourcePayment'
      str = payment.payment_id.presence ? 'payment' : 'invoice'
      id = payment.payment_id.presence || payment.invoice_id
      url = "#{ResourcePayment::STRIPE_LINK}/#{str.pluralize}/#{id}"
      text = str.upcase_first
    else
      case payment_type
      when 'StashEngine::Journal'
        url = Rails.application.routes.url_helpers.journal_admin_path(id: payment_id)
        text = payment.title
      when 'StashEngine::Tenant'
        url = Rails.application.routes.url_helpers.tenant_admin_path(id: payment_id)
        text = payment.short_name
      end
    end
    ActionController::Base.helpers.link_to text, url, target: '_blank'
  end
end
