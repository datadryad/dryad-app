require 'features_helper'

describe 'review ' do
  before(:each) do
    start_new_dataset!
  end

  describe 'without required fields' do
    before(:each) do
      navigate_to_review!
    end

    it 'disables submit' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).to be_disabled
    end
  end

  describe 'with required fields' do
    before(:each) do
      fill_required_fields!
      navigate_to_review!
      find_by_id('agree_to_license').click
      find_by_id('agree_to_payment').click
    end

    it 'allows submit' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).not_to be_disabled
    end

    it 'submits' do
      # get these now since they're only on the edit pages
      resource_id = current_resource_id
      resource = current_resource

      expect(StashEngine.repository).to receive(:submit).with(resource_id: resource_id)
      submit = find_button('submit_dataset', disabled: :all)
      submit.click

      expect(page).to have_content('My Datasets')
      expect(page).to have_content resource.title
    end
  end
end
