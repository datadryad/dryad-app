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

  let(:journal) { create(:journal, payment_plan: 'TIERED') }
  let(:user) { create(:user, role: 'admin', tenant_id: journal.id) }
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

    allow_any_instance_of(Aws::S3::Object).to receive(:exists?).and_return(true)

    metadata_builder.make_minimal
    metadata_builder.add_title(title)
    metadata_builder.add_journal(journal)

    ### CREATE dataset metadata
    metadata_hash = metadata_builder.hash
    metadata_hash[:authors][0][:affiliation] = journal.title
    @metadata_hash = metadata_hash
  end

  context 'for old system payer journal ' do
    let(:journal) { create(:journal, payment_plan: 'TIERED') }

    # can submit
    it_should_behave_like 'API submission flow', true, { status: 202 }
  end

  context 'for new system payer journal' do
    let(:journal) { create(:journal, payment_plan: '2025', covers_ldf: false) }

    # can submit
    it_should_behave_like 'API submission flow', true, { status: 202 }
  end

  context 'for non payer journal' do
    let(:journal) { create(:journal) }

    # can NOT submit, due to payment required
    it_should_behave_like 'API submission flow', false, { status: 403, error: 'You need to pay a Data Publishing Charge of $150 in order to submit.' }
  end
end
