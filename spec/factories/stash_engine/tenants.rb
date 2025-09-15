# == Schema Information
#
# Table name: stash_engine_tenants
#
#  id                 :string(191)      not null, primary key
#  authentication     :json
#  campus_contacts    :json
#  covers_dpc         :boolean          default(TRUE)
#  covers_ldf         :boolean          default(FALSE)
#  enabled            :boolean          default(TRUE)
#  long_name          :string(191)
#  low_income_country :boolean          default(FALSE)
#  partner_display    :boolean          default(TRUE)
#  payment_plan       :integer
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
FactoryBot.define do

  factory :tenant, class: StashEngine::Tenant do
    id { 'mock_tenant' }
    short_name do
      case id
      when 'email_auth'
        'Email Test'
      when 'dryad_ip'
        'Dryad IP Address Test'
      when 'match_tenant'
        'Match Tenant'
      when 'dryad'
        'Dryad'
      when 'ucop'
        'UC Office of the President'
      else
        'Mock Tenant'
      end
    end
    long_name do
      case id
      when 'email_auth'
        'Email Test Organization'
      when 'dryad_ip'
        'Dryad Data Platform IP Address Test'
      when 'match_tenant'
        'Author Match Tenant'
      when 'dryad'
        'Dryad Data Platform'
      when 'ucop'
        'University of California, Office of the President'
      else
        'Mockus Tenantus'
      end
    end
    authentication do
      case id
      when 'email_auth'
        { strategy: 'email', email_domain: 'example.org' }.to_json
      when 'dryad_ip'
        { strategy: 'ip_address', ranges: ['128.48.67.15/255.255.255.0', '127.0.0.1/255.255.255.0'] }.to_json
      when 'match_tenant'
        { strategy: 'author_match' }.to_json
      when 'ucop'
        { strategy: 'shibboleth', entity_id: 'urn:mace:incommon:ucop.edu', entity_domain: '.ucop.edu' }.to_json
      else
        { strategy: nil }.to_json
      end
    end
    campus_contacts { id == 'dryad' ? ['devs@datadryad.org'].to_json : [].to_json }
    enabled { true }
    partner_display do
      case id
      when 'email_auth', 'match_tenant', 'ucop'
        true
      else false end
    end
    sponsor_id { nil }

    after(:create) do |tenant|
      ror = create(:tenant_ror_org, tenant_id: tenant.id)
      create(:tenant_ror_org, tenant_id: tenant.sponsor_id, ror_id: ror.ror_id) if tenant.sponsor_id.present?
      if tenant.id == 'ucop'
        tenant.logo = StashEngine::Logo.new unless tenant.logo.present?
        tenant.logo.data = logo_ucop
        tenant.logo.save
        tenant.reload
      end

      create(:payment_configuration, partner: tenant, covers_dpc: true) if tenant.id.in?(%w[email_auth match_tenant ucop])
    end
  end

  factory :tenant_email, parent: :tenant, class: StashEngine::Tenant do
    id { 'email_auth' }
  end

  factory :tenant_ip, parent: :tenant, class: StashEngine::Tenant do
    id { 'dryad_ip' }
  end

  factory :tenant_match, parent: :tenant, class: StashEngine::Tenant do
    id { 'match_tenant' }
  end

  factory :tenant_dryad, parent: :tenant, class: StashEngine::Tenant do
    id { 'dryad' }
  end

  factory :tenant_ucop, parent: :tenant, class: StashEngine::Tenant do
    id { 'ucop' }
  end
end

# rubocop:disable Layout/LineLength
def logo_ucop = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAMAAAC6V+0/AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAaVBMVEUAAAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD/AAD///+kkpPsAAAAIXRSTlMABlem2PRWU93cUgOMiwKJUN5Vp6Ta8/HZ16NUBdtPiIq8tKWIAAAAAWJLR0QiXWVcrAAAAAd0SU1FB+cLFxUEFBnQr08AAACESURBVBjTbdDtEoIgFEXRg+BnSWpEkWjd93/JlGEsuO1/rhlkOMCeKKQqSyUrgaO6oVjbRTqd6adeB0yM6BLOUtaw3dHmOAoUxJpw5Whw46hgOdp/eMeDo4Pk+ETFcYZfcmu2qboc1/3xfWqvsJJ+JyPpuOhw/HdZv9P7yThrnZl9+PwAiOknqc4Zu0AAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjMtMTEtMjNUMjE6MDQ6MjArMDA6MDANo+62AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTExLTIzVDIxOjA0OjIwKzAwOjAwfP5WCgAAAABJRU5ErkJggg=='
# rubocop:enable Layout/LineLength
