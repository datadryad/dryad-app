require 'features_helper'

describe 'timed publication' do

  before(:each) do
    start_new_dataset!
    fill_required_fields!
    navigate_to_review!
  end

  it 'sets the embargo end date' do
    expect(page).to have_content('Choose Publication Date')

    today_button = find_by_id('today_button')
    expect(today_button).to be_checked

    future_button = find_by_id('future_button')
    expect(future_button).not_to be_checked

    future_button.click

    end_date = Date.today + 3.months

    fill_in_future_pub_date(end_date)

    # force focus change
    find_by_id('agree_to_license').click

    wait_for_ajax!

    resource = current_resource
    pub_date = resource.notional_publication_date.to_date
    expect(pub_date).to eq(end_date)

    embargo = resource.embargo
    embargo_end_date = embargo.end_date.to_date
    expect(embargo_end_date).to eq(end_date)
  end
end
