RSpec.feature 'HelpCenter', type: :feature, js: true do

  before(:each) do
    create(:tenant)
    visit help_path
  end

  it 'loads the search bar and menu' do
    expect(page).to have_text('Dryad help center')
    expect(page).to have_selector('#page-content input#help_search')
    expect(page).to have_text('Submission walkthrough')
  end

  it 'searches the help pages' do
    fill_in 'Search the help center', with: 'peer review'
    click_button 'Search'
    expect(page).to have_text('results for peer review')
    expect(page).to have_text('Private for Peer Review Fee')
  end

  it 'visits a page, moves the search bar and shows a submenu' do
    click_link 'File requirements'
    expect(page).to have_selector('#page-nav input#help_search')
    expect(page).to have_selector('#page-nav ul ul ul')
  end
end
