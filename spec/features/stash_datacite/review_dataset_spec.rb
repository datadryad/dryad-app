require 'rails_helper'

RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::DataFile
  include Mocks::Aws

  let(:user) { create(:user) }
  before(:each) { sign_in(user) }

  context :requirements_not_met do
    it 'should disable submit button', js: true do
      start_new_dataset
      navigate_to_review
      submit = find_button('submit_button')
      expect(submit).not_to be_nil
      expect(submit['aria-disabled'])
    end
  end

  context :requirements_met, js: true do
    before(:each) do
      mock_solr!
      mock_repository!
      mock_salesforce!
      mock_file_content!
      mock_aws!
    end

    it 'submit button should be enabled', js: true do
      start_new_dataset
      fill_required_fields
      navigate_to_review
      submit = find_button('submit_button')
      expect(submit).not_to be_nil
      expect(submit['aria-disabled']).to be(nil)

      # submits
      submit_form
      expect(page).to have_content(CGI.unescapeHTML(StashEngine::Resource.last.title.html_safe))
      expect(page).to have_content("Your dataset with the DOI #{StashEngine::Resource.last.identifier_uri} was submitted for curation")
    end
  end

  context :payment, js: true do
    before(:each) do
      start_new_dataset
      navigate_to_metadata
    end

    it 'charges user by default' do
      click_button 'Agreements'
      expect(page).to have_content("I agree\nto Dryad's payment terms")
    end

    it 'waives the fee when the institution will pay' do
      create(:tenant_email)
      user.update(tenant_id: 'email_auth')
      refresh
      click_button 'Agreements'
      expect(page).to have_text('Payment for this submission is sponsored by Email Test Organization')
    end

    it 'waives the fee when the journal will pay' do
      journal = create(:journal, title: 'Test Paying Journal', payment_plan_type: 'SUBSCRIPTION')
      click_button 'Connect'
      choose 'Yes'
      check 'Submitted manuscript'
      find_field('Journal name').send_keys(journal.title[0..4])
      expect(page).to have_text(journal.title)
      find_field('Journal name').send_keys(journal.title[5..])
      fill_in 'Manuscript number', with: 'NA'
      page.send_keys(:tab)

      expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
      click_button 'Agreements'
      expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
    end

    it "doesn't waive the fee when the journal won't pay" do
      journal = create(:journal, title: 'Test NonPaying Journal', payment_plan_type: nil)
      click_button 'Connect'
      choose 'Yes'
      check 'Submitted manuscript'
      find_field('Journal name').send_keys(journal.title[0..4])
      expect(page).to have_text(journal.title)
      find_field('Journal name').send_keys(journal.title[5..])
      fill_in 'Manuscript number', with: 'NA'
      page.send_keys(:tab)

      expect(page).not_to have_text("Payment for this submission is sponsored by #{journal.title}")
      click_button 'Agreements'
      expect(page).not_to have_text("Payment for this submission is sponsored by #{journal.title}")
    end

    it 'waives the fee when funder will pay' do
      create(:funder, name: 'Happy Clown School')
      click_button 'Support'
      fill_in_funder(name: 'Happy Clown School')

      click_button 'Agreements'
      expect(page).to have_text('Payment for this submission is sponsored by Happy Clown School')
    end

    it "doesn't waive the fee when funder won't pay" do
      click_button 'Support'
      fill_in_funder(name: 'Wiring Harness Solutions', value: '12XU')

      click_button 'Agreements'
      expect(page).not_to have_text('Payment for this submission is sponsored by')
    end
  end
end
