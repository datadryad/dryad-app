# == Schema Information
#
# Table name: stash_engine_tenants
#
#  id                 :string(191)      not null, primary key
#  authentication     :json
#  campus_contacts    :json
#  enabled            :boolean          default(TRUE)
#  long_name          :string(191)
#  low_income_country :boolean          default(FALSE)
#  partner_display    :boolean          default(TRUE)
#  short_name         :string(191)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  logo_id            :text(4294967295)
#  sponsor_id         :string(191)
#
# Indexes
#
#  index_stash_engine_tenants_on_id  (id)
#
require 'json'
require 'ostruct'
module StashEngine
  class Tenant < ApplicationRecord
    self.table_name = 'stash_engine_tenants'
    PAYMENT_PLANS = %w[SUBSCRIPTION TIERED 2025].freeze

    validates :id, presence: true, uniqueness: true
    validates :short_name, presence: true
    validates :long_name, presence: true
    validate :email_array

    belongs_to :logo, class_name: 'StashEngine::Logo', dependent: :destroy, optional: true
    belongs_to :sponsor, class_name: 'Tenant', inverse_of: :sponsored, optional: true
    has_many :sponsored, class_name: 'Tenant', primary_key: :id, foreign_key: :sponsor_id, inverse_of: :sponsor
    has_many :tenant_ror_orgs, -> { order(:created_at) }, class_name: 'StashEngine::TenantRorOrg', dependent: :destroy
    has_many :ror_orgs, class_name: 'StashEngine::RorOrg', through: :tenant_ror_orgs
    has_many :roles, class_name: 'StashEngine::Role', as: :role_object, dependent: :destroy
    has_many :users, through: :roles
    has_many :email_tokens, class_name: 'StashEngine::EmailToken', dependent: :destroy
    has_one :flag, class_name: 'StashEngine::Flag', as: :flaggable, dependent: :destroy
    has_one :payment_configuration, as: :partner, dependent: :destroy
    has_many :payment_logs, class_name: 'SponsoredPaymentLog', as: :payer

    accepts_nested_attributes_for :flag, allow_destroy: true
    accepts_nested_attributes_for :payment_configuration

    # return all enabled tenants sorted by name
    scope :enabled, -> { where(enabled: true).order(:short_name) }
    scope :partner_list, -> { enabled.where(partner_display: true) }
    scope :connect_list, -> { partner_list.joins(:payment_configuration).where(payment_configurations: { covers_dpc: true }) }
    scope :tiered, -> { enabled.joins(:payment_configuration).where(payment_configurations: { payment_plan: 'TIERED' }) }
    scope :fees_2025, -> { enabled.joins(:payment_configuration).where(payment_configurations: { payment_plan: '2025' }) }
    scope :sponsored, -> { enabled.distinct.joins(:sponsored) }

    def authentication
      JSON.parse(super, object_class: OpenStruct) if super.present?
    end

    def campus_contacts
      JSON.parse(super) if super.present?
    end

    def email_array
      campus_contacts&.each do |email|
        errors.add(:campus_contacts, "#{email} is not a valid email address") unless email.match?(EMAIL_REGEX)
      end
    end

    def consortium
      Tenant.where('id = ? or sponsor_id= ?', id, id)
    end

    def ror_ids
      tenant_ror_orgs.map(&:ror_id)
    end

    def self.find_by_ror_id(ror_id)
      StashEngine::Tenant.joins(:tenant_ror_orgs).where('stash_engine_tenant_ror_orgs.ror_id = ?', ror_id)
    end

    def country_name
      ror_org = ror_orgs.first
      return nil if ror_org.nil? || ror_org.country.nil?

      ror_org.country
    end

    def omniauth_login_path(params = nil)
      @omniauth_login_path ||= send(:"#{authentication.strategy}_login_path", params)
    end

    # generate login path for shibboleth & omniauth, this is unusual since we have multi-institution login,
    # so have to hack around limitations in the normal omniauth/shibboleth by directly addressing
    # shibboleth.sso
    def shibboleth_login_path(params = nil)
      extra_params = (params ? "?#{params.to_param}" : '')
      "https://#{Rails.application.default_url_options[:host]}/Shibboleth.sso/Login?" \
        "target=#{CGI.escape("#{callback_path_begin}shibboleth/callback#{extra_params}")}" \
        "&entityID=#{CGI.escape(authentication.entity_id)}"
    end

    def callback_path_begin
      "https://#{Rails.application.default_url_options[:host]}/auth/"
    end

    def full_url(path)
      d = Rails.application.default_url_options
      if d[:port].blank?
        URI::HTTPS.build(host: d[:host], path: path).to_s
      else
        URI::HTTPS.build(host: d[:host], port: d[:port], path: path).to_s
      end
    end

  end
end
