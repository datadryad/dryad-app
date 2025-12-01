RSpec.feature 'Search', type: :feature, js: true do
  include Mocks::RSolr

  before(:each) do
    mock_solr_frontend!
    create(:tenant)
  end

  it 'loads the results and filters' do
    visit new_search_path
    expect(page).to have_text('Search data')
    expect(page).to have_link('Advanced search')
    expect(page).to have_text('Results 1 to 10 of 20')

    expect(page).to have_text('Filter results')
    expect(page).to have_button('Research organizations')
    expect(page).to have_button('Journals')
    expect(page).to have_button('Publication years')
    expect(page).to have_button('File extensions')
    expect(page).to have_button('Subject keywords')
  end

  it 'loads affiliations instead of research orgs' do
    visit new_search_path(affiliation: "https://ror.org/#{Faker::Number.number(digits: 7)}")
    expect(page).to have_button('Author affiliations')
    expect(page).not_to have_button('Research organizations')
  end

  it 'loads advanced search filters' do
    visit advanced_search_path
    expect(page).to have_text('Advanced search')
    expect(page).to have_button('Search')

    click_button('Search', match: :first)
    expect(page).to have_text('Publication date')
    expect(page).to have_text('Dataset size')
    expect(page).not_to have_button('Publication years')
  end
end
