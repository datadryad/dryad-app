require 'features_helper'

describe 'admin' do
  before(:each) do
    log_in!
    visit('/')
  end

  it 'is just annoying' do
    expect(page).to have_title(home_page_title)
  end
end
