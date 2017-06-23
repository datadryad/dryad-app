require 'features_helper'

describe '/' do
  it 'redirects to /stash' do
    visit('/')
    expect(page).to have_current_path('/stash')
  end
end
