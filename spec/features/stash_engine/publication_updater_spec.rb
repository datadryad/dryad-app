require 'rails_helper'

RSpec.feature 'PublicationUpdater', type: :feature do
  include Mocks::Salesforce
  include Mocks::Datacite

  context 'test the helpers' do
    before(:each) do
      mock_salesforce!
      mock_datacite!
      @user = create(:user)
      @resource = create(:resource_published, user: @user)
      @params = {
        identifier_id: @resource.identifier.id,
        approved: false,
        rejected: false,
        authors: [
          { 'ORCID' => 'http://orcid.org/0000-0002-0955-3483', 'given' => 'Julia M.', 'family' => 'Petersen',
            'affiliation' => [{ 'name' => 'Hotel California' }] },
          { 'ORCID' => 'http://orcid.org/0000-0002-1212-2233', 'given' => 'Michelangelo', 'family' => 'Snow',
            'affiliation' => [{ 'name' => 'Catalonia' }] }
        ].to_json,
        provenance: 'crossref',
        publication_date: Date.new(2018, 8, 13),
        publication_doi: '10.1073/pnas.1718211115',
        publication_issn: '1234-1234',
        publication_name: 'Ficticious Journal',
        score: 6.0,
        title: 'High-skilled labour mobility in Europe before and after the 2004 enlargement'
      }
      @proposed_change = StashEngine::ProposedChange.create(@params)
    end

    it 'shows the proposed change', js: true do
      sign_in(create(:user, role: 'manager'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_content(@resource.title)
      expect(page).to have_content('Published')
      expect(page).to have_content(@proposed_change.title)
      expect(page).to have_content(@proposed_change.publication_name)
    end
  end
end
