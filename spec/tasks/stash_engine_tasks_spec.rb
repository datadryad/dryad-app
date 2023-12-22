describe 'identifiers:datasets_with_possible_articles_report', type: :task do
  let(:report_path) { File.join(REPORTS_DIR, 'datasets_with_possible_articles.csv') }

  before do
    identifier1 = create(:identifier, pub_state: 'published')
    resource = create(:resource, identifier_id: identifier1.id)
    create(:internal_data, data_type: 'publicationISSN', stash_identifier: identifier1)
    create(:related_identifier, resource: resource, related_identifier_type: 'doi', work_type: 'primary_article')

    # control record -- should not be included in CSV
    create(:identifier, pub_state: 'published')
  end

  it 'creates a CSV file with the correct data' do
    # when
    task.execute

    # then
    expect(File).to exist(report_path)

    csv_content = CSV.read(report_path, headers: true)
    expect(csv_content.headers).to eq(%w[ID Identifier ISSN])
    expect(csv_content.length).to eq(1)
    csv_content.each do |row|
      identifier = StashEngine::Identifier.find(row['ID'])
      expect(row['Identifier']).not_to be_nil
      expect(row['Identifier']).to eq(identifier.identifier)
      expect(row['ISSN']).not_to be_nil
      expect(row['ISSN']).to eq(identifier.publication_issn)
    end
  end
end
