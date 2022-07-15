# rubocop:disable Metrics/AbcSize
module Mocks
  module Tenant
    def mock_tenant!(covers_dpc: false)
      tenant = double(StashEngine::Tenant)

      auth_params = {
        strategy: 'none'
      }
      id_params = {
        provider: 'datacite',
        prefix: '10.5072',
        account: 'stash',
        password: '3cc9d3fbd9788148c6a32a1415fa673a',
        sandbox: true
      }
      repo_params = {
        domain: 'https://merritt-stage.cdlib.org',
        endpoint: 'http://mrtsword-stg.cdlib.org:39001/mrtsword/collection/cdl_dryaddev',
        username: 'some_fake_user',
        password: 'bogus_password'
      }

      setup_submocks(tenant: tenant, auth_params: auth_params, id_params: id_params, repo_params: repo_params,
                     covers_dpc: covers_dpc)
    end

    def mock_ip_tenant!(ip_string:, covers_dpc: true)
      tenant = double(StashEngine::Tenant)

      auth_params = {
        strategy: 'ip_address',
        ranges: [ip_string]
      }
      id_params = {
        provider: 'datacite',
        prefix: '10.5072',
        account: 'stash',
        password: '3cc9d3fbd9788148c6a32a1415fa673a',
        sandbox: true
      }
      repo_params = {
        domain: 'https://merritt-stage.cdlib.org',
        endpoint: 'http://mrtsword-stg.cdlib.org:39001/mrtsword/collection/cdl_dryaddev',
        username: 'some_fake_user',
        password: 'bogus_password'
      }

      setup_submocks(tenant: tenant, auth_params: auth_params, id_params: id_params, repo_params: repo_params,
                     covers_dpc: covers_dpc)
    end

    def setup_submocks(tenant:, auth_params:, id_params:, repo_params:, covers_dpc:)
      allow(tenant).to receive(:abbreviation).and_return('mock_tenant')
      allow(tenant).to receive(:authentication).and_return(OpenStruct.new(auth_params))
      allow(tenant).to receive(:campus_contacts).and_return(['contact@someuniversity.edu'])
      allow(tenant).to receive(:covers_dpc).and_return(covers_dpc)
      allow(tenant).to receive(:default_license).and_return('cc0')
      allow(tenant).to receive(:data_deposit_agreement).and_return(false)
      allow(tenant).to receive(:data_deposit_agreement?).and_return(false)
      allow(tenant).to receive(:enabled).and_return(true)
      allow(tenant).to receive(:full_url).and_return('http://datadryad.org')
      allow(tenant).to receive(:identifier_service).and_return(OpenStruct.new(id_params))
      allow(tenant).to receive(:long_name).and_return('Mockus Tenantus')
      allow(tenant).to receive(:logo_file).and_return('logo_blank.svg')
      allow(tenant).to receive(:partner_display).and_return(false)
      allow(tenant).to receive(:publisher_id).and_return('abc123')
      allow(tenant).to receive(:repository).and_return(OpenStruct.new(repo_params))
      allow(tenant).to receive(:ror_ids).and_return(nil)
      allow(tenant).to receive(:short_name).and_return('Mock Tenant')
      allow(tenant).to receive(:tenant_id).and_return('mock_tenant')

      allow_any_instance_of(StashEngine::User).to receive(:tenant).and_return(tenant)
      allow_any_instance_of(StashEngine::Resource).to receive(:tenant).and_return(tenant)
      allow(StashEngine::Tenant).to receive(:find).and_return(tenant)
    end
  end
end
# rubocop:enable Metrics/AbcSize
