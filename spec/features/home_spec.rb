require 'features_helper'

describe 'GET /' do
  before(:each) do
    visit('/')
  end

  it 'redirects to /stash' do
    expect(page).to have_current_path('/stash')
  end

  it 'is the home page' do
    home_html_erb = File.read("#{STASH_ENGINE_PATH}/app/views/stash_engine/pages/home.html.erb")
    title = home_html_erb[/page_title = '([^']+)'/, 1]
    expect(page).to have_title(title)
  end
end
