describe 'identifiers:datasets_with_possible_articles_report', type: :task do
  let(:report_path) { File.join(REPORTS_DIR, 'datasets_with_possible_articles.csv') }

  let!(:identifier_w_article) do
    # should not be included in the CSV
    identifier_w_article = create(:identifier, pub_state: 'published')
    resource = create(:resource, identifier_id: identifier_w_article.id)
    create(:resource_publication, resource: resource, publication_name: nil, publication_issn: '0000-000X')
    create(:related_identifier, resource: resource, related_identifier_type: 'doi', work_type: 'primary_article')

    identifier_w_article.reload
  end

  let!(:identifier_wo_article) do
    # should be included in the CSV
    identifier_wo_article = create(:identifier, pub_state: 'published')
    resource = create(:resource, identifier_id: identifier_wo_article.id)
    create(:resource_publication, resource: resource, publication_name: nil, publication_issn: '0000-000X')

    identifier_wo_article.reload
  end

  before(:each) do
    # control record -- should not be included in CSV
    create(:identifier, pub_state: 'published')
  end

  it 'preloads the Rails environment' do
    expect(task.prerequisites).to include 'environment'
  end

  it 'creates a CSV file with the correct data' do
    # when
    task.execute

    # then
    expect(File).to exist(report_path)

    csv_content = CSV.read(report_path, headers: true)
    expect(csv_content.headers).to eq(%w[ID Identifier ISSN])
    expect(csv_content.length).to eq(1)
    first_row = csv_content.first
    expect(first_row['Identifier']).not_to be_nil
    expect(first_row['Identifier']).to eq(identifier_wo_article.identifier)
    expect(first_row['ISSN']).not_to be_nil
    expect(first_row['ISSN']).to eq(identifier_wo_article.publication_issn)
    # csv_content.each do |row|
    #   identifier = StashEngine::Identifier.find(row['ID'])
    #   expect(row['Identifier']).not_to be_nil
    #   expect(row['Identifier']).to eq(identifier.identifier)
    #   expect(row['ISSN']).not_to be_nil
    #   expect(row['ISSN']).to eq(identifier.publication_issn)
    # end
  end
end

describe 'identifiers:remove_abandoned_datasets', type: :task do
  include Mocks::Salesforce
  include Mocks::RSolr

  let!(:system_user) { create(:user, id: 0) }
  let(:user) { create(:user) }
  let(:identifier) { create(:identifier, publication_date: nil) }
  let!(:resource) { create(:resource, identifier: identifier, publication_date: nil) }
  let!(:data_file) { create(:data_file, resource_id: resource.id) }
  let!(:software_file) { create(:software_file, resource_id: resource.id) }
  let!(:supp_file) { create(:supp_file, resource_id: resource.id) }
  let(:double_aws) { double('AWS', delete_dir: true, delete_file: true) }

  it 'preloads the Rails environment' do
    expect(task.prerequisites).to include 'environment'
  end

  before do
    mock_salesforce!
    mock_solr!
    allow(Stash::Aws::S3).to receive(:new).and_return(double_aws)
    allow(Kernel).to receive(:exit).and_return(true)
  end

  after { Timecop.return }

  context 'when resource is in_progress' do
    let!(:ca) { create(:curation_activity, status: 'in_progress', resource: resource, user_id: user.id) }

    context 'after less then 2 years' do
      let(:action_time) { 2.years.from_now - 1.day }

      include_examples 'does not delete files'
    end

    context 'after more then 2 years' do
      let(:action_time) { 2.years.from_now + 1.day }

      include_examples 'deletes resource files form S3'
    end
  end

  context 'when resource is withdrawn' do
    let!(:ca) { create(:curation_activity, status: 'withdrawn', resource: resource, user_id: user.id) }

    context 'after less then 2 years' do
      let(:action_time) { 2.years.from_now - 1.day }

      include_examples 'does not delete files'
    end

    context 'after more then 2 years' do
      let(:action_time) { 2.years.from_now + 1.day }

      include_examples 'deletes resource files form S3'
    end
  end

  (StashEngine::CurationActivity.statuses.values - %w[withdrawn in_progress]).each do |status|
    context "when resource is in `#{status}` status" do
      let!(:ca) { create(:curation_activity, status: status, resource: resource, user_id: user.id) }

      context 'after less then 2 years' do
        let(:action_time) { 2.years.from_now - 1.day }

        include_examples 'does not delete files'
      end

      context 'after more then 2 years' do
        let(:action_time) { 2.years.from_now + 1.day }

        include_examples 'does not delete files'
      end
    end
  end

  context 'when resource is in progress but was at one pint published' do
    let!(:ca) { create(:curation_activity, status: 'published', resource: resource, user_id: user.id, created_at: 1.minute.ago) }
    let!(:ca2) { create(:curation_activity, status: 'in_progress', resource: resource, user_id: user.id) }

    context 'after less then 2 years' do
      let(:action_time) { 2.years.from_now - 1.day }

      include_examples 'does not delete files'
    end

    context 'after more then 2 years' do
      let(:action_time) { 2.years.from_now + 1.day }

      include_examples 'does not delete files'
    end
  end
end
