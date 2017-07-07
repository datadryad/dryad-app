require 'features_helper'

describe 'new dataset' do
  attr_reader :start_new_dataset

  before(:each) do
    visit('/')
    first(:link_or_button, 'Login').click
    @start_new_dataset = first(:link_or_button, 'Start New Dataset')
    expect(start_new_dataset).not_to be_nil
  end

  describe 'Start New Dataset' do
    before(:each) do
      start_new_dataset.click
    end

    it 'starts a new dataset' do
      expect(page).to have_content('Describe Your Dataset')
      title_field = find_field('title')
      expect(title_field.value).to be_blank
    end
  end
end
