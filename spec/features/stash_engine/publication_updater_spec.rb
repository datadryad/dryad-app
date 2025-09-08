require 'rails_helper'

RSpec.feature 'PublicationUpdater', type: :feature, js: true do
  include Mocks::Salesforce
  include Mocks::Datacite
  include Mocks::CurationActivity

  before(:each) do
    mock_salesforce!
    mock_datacite!
  end

  context 'display and filtering' do
    let(:resources) { 3.times.map { create(:resource_published) } }
    let(:proposed_changes) { resources.map { |r| create(:proposed_change, identifier: r.identifier) } }

    before(:each) do
      resources.each { |r| r.identifier.reload }
      proposed_changes.each(&:reload)
      sign_in(create(:user, role: 'manager'))
    end

    it 'shows the proposed changes' do
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_content('3 results')
      expect(page).to have_content('Published', minimum: 3)
      expect(page).to have_content(resources[1].title)
      expect(page).to have_content(proposed_changes[1].title)
      expect(page).to have_content(proposed_changes[1].publication_name)
    end

    it 'filters the proposed changes' do
      r = 2.times.map { create(:resource, :submitted) }
      pc = r.map { |n| create(:proposed_change, :preprint, identifier: n.identifier) }
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_content('5 results')
      expect(page).to have_content('Published', minimum: 3)
      expect(page).to have_content('Submitted', minimum: 2)

      select 'Submitted'
      click_button 'Search'
      expect(page).to have_content('2 results')
      expect(page).to have_content(r[1].title)
      expect(page).to have_content(pc[1].title)
      expect(page).to have_content(pc[1].publication_name)

      click_button 'Reset'
      expect(page).to have_content('5 results')

      select 'Likely preprints'
      click_button 'Search'
      expect(page).to have_content('2 results')
      expect(page).to have_select("select_type_#{pc[1].id}", selected: 'Preprint')
      expect(page).to have_content(r[1].title)
      expect(page).to have_content(pc[1].title)
      expect(page).to have_content(pc[1].publication_name)
    end
  end

  context 'accepting changes' do
    let(:resources) do
      [create(:resource_published),
       create(:resource, :submitted, hold_for_peer_review: true)]
    end
    let(:proposed_changes) { resources.map { |r| create(:proposed_change, identifier: r.identifier) } }

    before(:each) do
      neuter_curation_callbacks!
      allow_any_instance_of(StashEngine::Identifier).to receive(:payment_needed?).and_return(false)
      allow_any_instance_of(StashEngine::UserMailer).to receive(:peer_review_pub_linked).and_return(true)
      resources.each { |r| r.identifier.reload }
      proposed_changes.each(&:reload)
      sign_in(create(:user, role: 'manager'))
    end

    it 'accepts a change for a published resource' do
      visit stash_url_helpers.publication_updater_path
      within(:css, "form[action=\"/publication_updater/#{proposed_changes[0].id}\"]", match: :first) do
        click_button 'Accept'
      end

      expect(page).not_to have_content(proposed_changes[0].title)
      expect(resources[0].identifier.publication_name).to eq(proposed_changes[0].publication_name)
      expect(resources[0].identifier.publication_article_doi).to include(proposed_changes[0].publication_doi)
    end

    it 'accepts a change and submits a PPR resource' do
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_content('Private for peer review', minimum: 2)
      within(:css, "form[action=\"/publication_updater/#{proposed_changes[1].id}\"]", match: :first) do
        click_button 'Accept'
      end

      expect(page).not_to have_content(proposed_changes[1].title, wait: 15)
      expect(resources[1].identifier.publication_name).to eq(proposed_changes[1].publication_name)
      expect(resources[1].identifier.publication_article_doi).to include(proposed_changes[1].publication_doi)
      expect(resources[1].current_curation_status).to eq('submitted')
    end
  end

  context 'match history page' do
    let(:resources) { 3.times.map { create(:resource_published) } }
    let(:proposed_changes) { resources.map { |r| create(:proposed_change, identifier: r.identifier) } }

    before(:each) do
      resources.each { |r| r.identifier.reload }
      proposed_changes.each(&:reload)
      sign_in(create(:user, role: 'manager'))
    end

    it 'fills the log' do
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_content('3 results')
      expect(page).to have_content('Published', minimum: 3)
      within(:css, "form[action=\"/publication_updater/#{proposed_changes[0].id}\"]", match: :first) do
        click_button 'Accept'
      end
      within(:css, "form[action=\"/publication_updater/#{proposed_changes[1].id}\"]:last-of-type") do
        click_button 'Reject'
      end
      within(:css, "form[action=\"/publication_updater/#{proposed_changes[2].id}\"]", match: :first) do
        click_button 'Accept'
      end
      click_link 'Match history'
      expect(page).to have_content('Approved', count: 2)
      expect(page).to have_content('Rejected', count: 1)
    end
  end
end
