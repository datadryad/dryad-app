require 'byebug'

describe 'identifiers:datasets_with_possible_articles_report', type: :task do
  let(:report_path) { File.join(REPORTS_DIR, 'datasets_with_possible_articles.csv') }

  let!(:identifier_w_article) do
    # should not be included in the CSV
    identifier_w_article = create(:identifier, pub_state: 'published')
    resource = create(:resource, identifier_id: identifier_w_article.id)
    create(:internal_data, data_type: 'publicationISSN', stash_identifier: identifier_w_article)
    create(:related_identifier, resource: resource, related_identifier_type: 'doi', work_type: 'primary_article')

    identifier_w_article
  end

  let!(:identifier_wo_article) do
    # should be included in the CSV
    identifier_wo_article = create(:identifier, pub_state: 'published')
    create(:resource, identifier_id: identifier_wo_article.id)
    create(:internal_data, data_type: 'publicationISSN', stash_identifier: identifier_wo_article)

    identifier_wo_article
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
