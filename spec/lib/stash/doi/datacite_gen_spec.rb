require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Doi
    RSpec.describe DataciteGen do
      include Mocks::Tenant

      describe 'Cirneco replacement methods' do
        before(:each) do
          mock_tenant!
          @resource = create(:resource)
          @datacite_gen = DataciteGen.new(resource: @resource)
          # the commented out section pulled in more packaging than needed just to create the DC4 XML
          # sp = Stash::Merritt::SubmissionPackage.new(resource: @resource, packaging: nil)
          # @dc4_xml = sp.dc4_builder.contents
          dc_xml = Datacite::Mapping::DataciteXMLFactory.new(
            doi_value: @resource.identifier_value,
            se_resource_id: @resource.id,
            total_size_bytes: @resource.size,
            version: @resource.version_number
          )
          @dc4_xml = dc_xml.build_datacite_xml
        end

        describe :post_metadata do
          it 'creates a successful sandbox post request to DataCite' do
            repo = APP_CONFIG[:repository]
            stub_request(:post, 'https://mds.test.datacite.org/metadata')
              .with(headers: { 'Authorization' => ActionController::HttpAuthentication::Basic
                                                      .encode_credentials(repo.username, repo.password),
                               'Content-Type' => 'application/xml;charset=UTF-8',
                               'Host' => 'mds.test.datacite.org' })
              .to_return(status: 201, body: 'operation succeeded') # not sure what real body is from DC, but we don't use it

            res = @datacite_gen.send(:post_metadata, @dc4_xml, { username: repo.username, password: repo.password, sandbox: true })
            expect(res.status).to eq(201)
          end

          it 'creates a successful post request to DataCite' do
            repo = APP_CONFIG[:repository]
            stub_request(:post, 'https://mds.datacite.org/metadata')
              .with(headers: { 'Authorization' => ActionController::HttpAuthentication::Basic
                                                      .encode_credentials(repo.username, repo.password),
                               'Content-Type' => 'application/xml;charset=UTF-8',
                               'Host' => 'mds.datacite.org' })
              .to_return(status: 201, body: 'operation succeeded') # not sure what real body is from DC, but we don't use it
            res = @datacite_gen.send(:post_metadata, @dc4_xml, { username: repo.username, password: repo.password, sandbox: false })
            expect(res.status).to eq(201)
          end
        end

        describe :put_doi do
          it 'creates a successful sandbox put request to DataCite' do
            repo = APP_CONFIG[:repository]
            bare_id = @resource.identifier.identifier
            stub_request(:put, "https://mds.test.datacite.org/doi/#{bare_id}")
              .with(headers: { 'Authorization' => ActionController::HttpAuthentication::Basic
                                                      .encode_credentials(repo.username, repo.password),
                               'Content-Type' => 'application/xml;charset=UTF-8',
                               'Host' => 'mds.test.datacite.org' })
              .to_return(status: 201, body: 'operation succeeded') # not sure what real body is from DC, but we don't use it
            res = @datacite_gen.send(:put_doi, bare_id, { username: repo.username, password: repo.password, sandbox: true })
            expect(res.status).to eq(201)
          end

          it 'creates a successful put request to DataCite' do
            bare_id = @resource.identifier.identifier
            repo = APP_CONFIG[:repository]
            stub_request(:put, "https://mds.datacite.org/doi/#{bare_id}")
              .with(headers: { 'Authorization' => ActionController::HttpAuthentication::Basic
                                                      .encode_credentials(repo.username, repo.password),
                               'Content-Type' => 'application/xml;charset=UTF-8',
                               'Host' => 'mds.datacite.org' })
              .to_return(status: 201, body: 'operation succeeded') # not sure what real body is from DC, but we don't use it
            res = @datacite_gen.send(:put_doi, bare_id, { username: repo.username, password: repo.password, sandbox: false })
            expect(res.status).to eq(201)
          end

        end

        describe :get_doi do
          it 'creates a successful sandbox get request to DataCite' do
            bare_id = @resource.identifier.identifier
            repo = APP_CONFIG[:repository]
            stub_request(:get, "https://mds.test.datacite.org/doi/#{bare_id}")
              .with(headers: { 'Authorization' => ActionController::HttpAuthentication::Basic
                                                      .encode_credentials(repo.username, repo.password),
                               'Host' => 'mds.test.datacite.org' })
              .to_return(status: 200, body: 'operation succeeded') # not sure what real body is from DC, but we don't use it
            res = @datacite_gen.send(:get_doi, bare_id, { username: repo.username, password: repo.password, sandbox: true })
            expect(res.status).to eq(200)
          end

          it 'creates a successful get request to DataCite' do
            bare_id = @resource.identifier.identifier
            repo = APP_CONFIG[:repository]
            stub_request(:get, "https://mds.datacite.org/doi/#{bare_id}")
              .with(headers: { 'Authorization' => ActionController::HttpAuthentication::Basic
                                                      .encode_credentials(repo.username, repo.password),
                               'Host' => 'mds.datacite.org' })
              .to_return(status: 200, body: 'operation succeeded') # not sure what real body is from DC, but we don't use it

            res = @datacite_gen.send(:get_doi, bare_id, { username: repo.username, password: repo.password, sandbox: false })
            expect(res.status).to eq(200)
          end
        end
      end
    end
  end
end
