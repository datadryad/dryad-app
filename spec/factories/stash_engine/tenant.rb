FactoryBot.define do

  factory :tenant, class: StashEngine::Tenant do
    id { 'mock_tenant' }
    short_name do
      case id
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
    payment_plan { nil }
    enabled { true }
    partner_display do
      case id
      when 'match_tenant', 'ucop'
        true
      else false end
    end
    covers_dpc do
      case id
      when 'match_tenant', 'ucop'
        true
      else false end
    end
    sponsor_id { nil }

    after(:create) do |tenant|
      create(:tenant_ror_org, tenant_id: tenant.id)
    end
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
