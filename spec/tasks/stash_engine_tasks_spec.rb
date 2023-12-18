describe 'identifiers:datasets_with_possible_articles_report', type: :task do
  let(:report_path) { File.join(REPORTS_DIR, 'datasets_with_possible_articles.csv') }

  before do
    # create(:identifier, internal_data: [build(:internal_datum, data_type: 'publicationISSN')])
    # create(:identifier, internal_data: [build(:internal_datum, data_type: 'publicationDOI')])
    create(:identifier)
  end

  it 'creates a CSV file with the correct data' do
    # when
    task.invoke

    # then
    expect(File).to exist(report_path)

    csv_content = CSV.read(report_path, headers: true)
    expect(csv_content.headers).to eq(%w[ID Identifier ISSN])
    expect(csv_content.length).to eq(0)
    csv_content.each do |row|
      identifier = StashEngine::Identifier.find(row['ID'])
      expect(row['Identifier']).not_to be_nil
      expect(row['Identifier']).to eq(identifier.identifier)
      expect(row['ISSN']).not_to be_nil
      expect(row['ISSN']).to eq(identifier.publication_issn)
    end
  end
end
