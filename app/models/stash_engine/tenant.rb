require 'json'
require 'ostruct'
module StashEngine
  class Tenant < ApplicationRecord
    self.table_name = 'stash_engine_tenants'
    belongs_to :sponsor, class_name: 'Tenant', inverse_of: :sponsored, optional: true
    has_many :sponsored, class_name: 'Tenant', primary_key: :id, foreign_key: :sponsor_id, inverse_of: :sponsor
    has_many :tenant_ror_orgs, class_name: 'StashEngine::TenantRorOrg', dependent: :destroy
    has_many :ror_orgs, class_name: 'StashEngine::RorOrg', through: :tenant_ror_orgs
    has_many :roles, class_name: 'StashEngine::Role', as: :role_object
    has_many :users, through: :roles

    enum payment_plan: {
      tiered: 0
    }

    # return all enabled tenants sorted by name
    scope :enabled, -> { where(enabled: true).order(:short_name) }
    scope :partner_list, -> { enabled.where(partner_display: true) }
    scope :tiered, -> { enabled.where(payment_plan: :tiered) }
    scope :sponsored, -> { enabled.distinct.joins(:sponsored) }

    def logo_file
      @logo_file ||= begin
        tenant_images_path = File.join(Rails.root, 'app', 'assets', 'images', 'tenants')
        logo_filenames = %w[svg png jpg].lazy.map { |ext| "logo_#{id}.#{ext}" }
        logo_filenames.find do |filename|
          image_file = File.join(tenant_images_path, filename)
          File.exist?(image_file)
        end || ''
      end
    end

    def data_deposit_agreement?
      dda = File.join(Rails.root, 'app', 'views', 'tenants', id, '_dda.html.erb')
      File.exist?(dda)
    end

    def authentication
      JSON.parse(super, object_class: OpenStruct)
    end

    def campus_contacts
      JSON.parse(super)
    end

    def consortium
      Tenant.where('id = ? or sponsor_id= ?', id, id)
    end

    def ror_ids
      tenant_ror_orgs.map(&:ror_id)
    end

    def omniauth_login_path(params = nil)
      @omniauth_login_path ||= send("#{authentication.strategy}_login_path".intern, params)
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
      "https://#{Rails.application.default_url_options[:host]}#{APP_CONFIG.stash_mount}/auth/"
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
