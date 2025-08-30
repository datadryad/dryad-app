require 'rails_helper'
RSpec.feature 'Dashboard', type: :feature, js: true do
  include DatasetHelper
  include Mocks::Salesforce
  include Mocks::Datacite

  before(:each) do
    mock_salesforce!
    mock_datacite!
    create(:tenant)
  end

  describe :user_datasets do
    let(:user) { create(:user, tenant_id: 'email_auth') }
    let(:resources) do
      [
        create(:resource, user: user),
        create(:resource, :submitted, user: user, hold_for_peer_review: true),
        create(:resource, :submitted, user: user),
        create(:resource_published, user: user)
      ]
    end

    before(:each) { resources.each { |r| r.identifier.reload } }

    context 'listing the datasets' do
      before(:each) { sign_in(user) }

      it 'shows 4 datasets' do
        expect(page).to have_css('#user_datasets li', count: 4)
      end

      it 'organizes datasets correctly' do
        expect(page).to have_text('Needs attention')
        expect(page).to have_css('#user_in-progress li', count: 1)
        expect(find('#user_in-progress li')).to have_text(resources[0].title)
        expect(find('#user_in-progress li')).to have_text('In progress')

        expect(page).to have_text('Kept private')
        expect(page).to have_css('#user_private li', count: 1)
        expect(find('#user_private li')).to have_link(resources[1].title)
        expect(find('#user_private li')).to have_text('Private for peer review')

        expect(page).to have_text('Curation')
        expect(page).to have_css('#user_processing li', count: 1)
        expect(find('#user_processing li')).to have_link(resources[2].title)
        expect(find('#user_processing li')).to have_text('Submitted')

        expect(page).to have_text('Complete')
        expect(page).to have_css('#user_complete li', count: 1)
        expect(find('#user_complete li')).to have_link(resources[3].title)
        expect(find('#user_complete li')).to have_text('Published')
      end
    end

    context 'dataset in curation' do
      let(:curator) { create(:user, role: 'curator') }

      before(:each) do
        create(:curation_activity, resource: resources[2], user: curator, status: 'curation')
      end

      it 'correctly places datasets in curation' do
        sign_in(user)
        expect(page).to have_css('#user_datasets li', count: 4)
        expect(page).to have_text('Curation')
        expect(page).to have_text('Curation')
        expect(page).to have_css('#user_processing li', count: 1)
        expect(find('#user_processing li')).to have_link(resources[2].title)
      end

      it 'correctly places datasets edited by a curator' do
        Timecop.travel(Time.now.utc + 1.minute)
        create(:resource, identifier: resources[2].identifier, user: user, current_editor_id: curator.id)
        sign_in(user)
        expect(page).to have_css('#user_datasets li', count: 4)
        expect(page).to have_text('Curation')
        expect(page).to have_css('#user_processing li', count: 1)
        expect(find('#user_processing li')).to have_text('In progress')
        expect(find('#user_processing li')).to have_text("#{curator.name} is editing")
        Timecop.return
      end
    end

    context 'new dataset' do
      it 'creates and shows a new dataset' do
        sign_in(user)
        start_new_dataset
        click_link 'My datasets'
        expect(page).to have_css('#user_datasets li', count: 5)
        expect(page).to have_css('#user_in-progress li', count: 2)
        expect(find('#user_in-progress')).to have_text('[No title supplied]')
      end
    end

    context 'special buttons' do
      before(:each) { sign_in(user) }

      it 'releases from peer review' do
        # complete submission
        create(:description, resource: resources[1], description_type: 'technicalinfo')
        create(:description, resource: resources[1], description_type: 'usage_notes', description: nil)
        create(:data_file, resource: resources[1])
        # release submission
        click_button 'Release for curation'
        expect(page).to have_text('Is this dataset ready for curation and publication?')
        click_button 'Yes'

        expect(page).not_to have_text('Kept private')
        expect(page).to have_text('Curation')
        expect(page).to have_css('#user_processing li', count: 2)
        expect(find('#user_processing')).to have_link(resources[1].title)
      end

      it 'links a primary article' do
        doi = Faker::Pid.doi
        click_button 'Link article'
        expect(page).to have_text('Link primary article')
        fill_in 'searchselect-journal__input', with: 'Test Journal'
        fill_in 'related_identifier', with: doi
        click_button 'Submit'
        expect(page).not_to have_button('Link article')
        expect(resources[3].identifier.publication_article_doi).to include(doi)
      end
    end
  end
end
