require_relative 'helpers'
require 'fixtures/stash_api/metadata'

RSpec.describe 'SubmissionFlow', type: :request do
  include DatasetHelper
  include Mocks::Aws
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe

  let(:tenant) { create(:tenant_dryad) }
  let(:user) { create(:user, role: 'admin', tenant_id: tenant.id) }
  let(:doorkeeper_application) do
    create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', owner_id: user.id, owner_type: 'StashEngine::User')
  end
  let(:access_token) { get_access_token(doorkeeper_application: doorkeeper_application) }
  let(:headers) { default_authenticated_headers(access_token) }

  let(:metadata_builder) { Fixtures::StashApi::Metadata.new }
  let(:title) { 'Title for dataset full submission flow test through API' }

  before do
    host! 'my.example.org'
    mock_aws!
    mock_solr!
    mock_salesforce!
    mock_stripe!
    mock_datacite!

    allow_any_instance_of(::Aws::S3::Object).to receive(:exists?).and_return(true)

    metadata_builder.make_minimal
    metadata_builder.add_title(title)
  end

  it 'has proper flow' do
    ### Test token - returns welcome message and authenticated user id
    post '/api/v2/test', headers: headers
    json_response = response_body_hash
    expect(/Welcome application owner.+$/).to match(json_response[:message])
    expect(user.id).to eql(json_response[:user_id])

    ### LIST dataset - returns no datasets
    get '/api/v2/datasets', headers: headers
    json_response = response_body_hash
    expect(json_response[:total]).to eq(0)

    ### CREATE dataset
    create_params = metadata_builder.json
    metadata_hash = metadata_builder.hash
    response_code = post '/api/v2/datasets', params: create_params, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(201)
    doi = json_response[:identifier]
    identifier = StashEngine::Identifier.find_by(identifier: doi.split(':').last)
    resource = StashEngine::Resource.find(json_response[:id])
    resource.submitter.update(orcid: resource.authors.first.author_orcid)

    expect(/doi:10./).to match(doi)
    expect(metadata_hash[:title]).to eq(json_response[:title])
    expect(metadata_hash[:abstract]).to eq(json_response[:abstract])
    in_author = metadata_hash[:authors].first
    out_author = json_response[:authors].first
    expect(json_response[:id]).to eq(resource.id)
    expect(out_author[:email]).to eq(in_author[:email])
    expect(out_author[:affiliation]).to eq(in_author[:affiliation])
    expect(json_response[:title]).to eq(title)
    expect(json_response[:keywords]).to eq(metadata_hash[:keywords])
    expect(json_response[:fieldOfScience]).to eq(metadata_hash[:fieldOfScience])
    expect(json_response[:versionNumber]).to eq(1)
    expect(json_response[:versionStatus]).to eq('in_progress')
    expect(json_response[:curationStatus]).to eq('In progress')
    expect(json_response[:lastModificationDate]).to eq(Date.today.to_s)
    expect(json_response[:visibility]).to eq('restricted')
    expect(json_response[:userId]).to eq(user.id)
    expect(json_response[:license]).to eq(Stash::Wrapper::License::CC_ZERO.uri.to_s)
    expect(json_response[:editLink]).to eq("/edit/#{CGI.escape(doi)}/#{identifier.edit_code}")

    ### SHOW dataset
    response_code = get "/api/v2/datasets/#{CGI.escape(doi)}", headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:identifier]).to eq(doi)
    expect(json_response[:id]).to eq(resource.id)

    ### UPDATE dataset
    update_params = metadata_hash.merge({ abstract: 'New abstract', methods: 'New Method' })
    response_code = put "/api/v2/datasets/#{CGI.escape(doi)}", params: update_params.to_json, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:identifier]).to eq(doi)
    expect(json_response[:id]).to eq(resource.id)
    expect(json_response[:abstract]).to eq(update_params[:abstract])
    expect(json_response[:methods]).to eq(update_params[:methods])

    ### UPLOAD file
    file = fixture_file_upload('spec/fixtures/zipfiles/test_zip.zip')
    response_code = put "/api/v2/datasets/#{CGI.escape(doi)}/files/test_zip.zip", params: { file: file }, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(201)
    expect(json_response[:url]).to be_nil
    expect(json_response[:path]).to eq('test_zip.zip')
    expect(json_response[:status]).to eq('created')

    ### UPLOAD README file
    file = fixture_file_upload('spec/fixtures/README.md')
    response_code = put "/api/v2/datasets/#{CGI.escape(doi)}/files/README.md", params: { file: file }, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(201)
    expect(json_response[:url]).to be_nil
    expect(json_response[:path]).to eq('README.md')
    expect(json_response[:status]).to eq('created')

    ### LIST dataset version files
    response_code = get "/api/v2/versions/1/files", headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(200)
    expect(json_response[:count]).to eq(2)
    expect(json_response[:total]).to eq(2)
    expect(json_response[:_embedded]['stash:files'].map { |f| f[:path] }).to match_array(['README.md', 'test_zip.zip'])
    expect(json_response[:_embedded]['stash:files'].map { |f| f[:status] }).to match_array(['created', 'created'])

    ### UPDATE dataset status
    params = { op: 'replace', path: '/versionStatus', value: 'submitted' }

    response_code = patch "/api/v2/datasets/#{CGI.escape(doi)}", params: params.to_json, headers: headers
    json_response = response_body_hash
    expect(response_code).to eq(202)
    expect(json_response[:identifier]).to eq(doi)
    expect(json_response[:id]).to eq(resource.id)
    expect(json_response[:versionStatus]).to eq('processing')
    expect(json_response[:curationStatus]).to eq('In progress')
  end
end
