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
    end

    it 'allows submit' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).not_to be_disabled
    end
  end
end
