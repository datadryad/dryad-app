require 'rails_helper'

RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::DataFile
  include Mocks::Aws

  let(:user) { create(:user) }
  before { sign_in(user) }

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
    before do
      mock_solr!
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
      expect(page).to have_content(
        "Your dataset with the DOI #{StashEngine::Resource.last.identifier_uri} was submitted and is awaiting payment of your issued invoice."
      )
    end
  end

  context :payment, js: true do
    let(:ror) { create(:ror_org, name: 'Happy Clown School') }
    let!(:funder) { create(:funder, name: 'Happy Clown School', ror_id: ror.ror_id) }

    before do
      mock_rors_solr!(include_rors: [ror])
      start_new_dataset
      navigate_to_metadata
    end

    it 'charges user by default' do
      click_button 'Agreements'
      expect(page).to have_content("I agree\nto Dryad's payment terms")
    end

    it 'waives the fee when the institution will pay' do
      tenant = create(:tenant_email)
      create(:payment_configuration, partner: tenant, payment_plan: '2025')

      user.update(tenant_id: 'email_auth')
      refresh
      click_button 'Agreements'
      expect(page).to have_text('Payment for this submission is currently sponsored by Email Test Organization')
    end

    it 'waives the fee when the journal will pay' do
      org = create(:journal_organization)
      journal = create(:journal, title: 'Test Paying Journal', sponsor: org)
      create(:payment_configuration, partner: org, payment_plan: 'SUBSCRIPTION')

      click_button 'Connect'
      choose 'Yes'
      check 'Submitted manuscript'
      find_field('Journal name').send_keys(journal.title[0..4])
      expect(page).to have_text(journal.title)
      find_field('Journal name').send_keys(journal.title[5..])
      fill_in 'Manuscript number', with: 'NA'
      page.send_keys(:tab)

      expect(page).to have_text("Payment for this submission is currently sponsored by #{journal.title}")
      click_button 'Agreements'
      expect(page).to have_text("Payment for this submission is currently sponsored by #{journal.title}")
    end

    it "doesn't waive the fee when the journal won't pay" do
      journal = create(:journal, title: 'Test NonPaying Journal')
      click_button 'Connect'
      choose 'Yes'
      check 'Submitted manuscript'
      find_field('Journal name').send_keys(journal.title[0..4])
      expect(page).to have_text(journal.title)
      find_field('Journal name').send_keys(journal.title[5..])
      fill_in 'Manuscript number', with: 'NA'
      page.send_keys(:tab)

      expect(page).not_to have_text("Payment for this submission is currently sponsored by #{journal.title}")
      click_button 'Agreements'
      expect(page).not_to have_text("Payment for this submission is currently sponsored by #{journal.title}")
    end

    it 'waives the fee when funder will pay' do
      funder.payment_configuration.update(payment_plan: '2025')
      click_button 'Support'
      find_field('Granting organization').send_keys('Happy Clown School')
      expect(page).to have_css('.searchselect ul li[name="Happy Clown School"]', wait: 5)
      page.send_keys(:tab)

      click_button 'Agreements'
      expect(page).to have_text('Payment for this submission is currently sponsored by Happy Clown School', wait: 5)
    end

    it "doesn't waive the fee when funder won't pay" do
      click_button 'Support'
      fill_in_funder(name: 'Wiring Harness Solutions', value: '12XU')

      click_button 'Agreements'
      expect(page).not_to have_text('Payment for this submission is currently sponsored by')
    end
  end
end
