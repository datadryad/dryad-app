require 'features_helper'

describe 'timed publication' do

  before(:each) do
    visit('/')
    first(:link_or_button, 'Login').click
    first(:link_or_button, 'Start New Dataset').click
    fill_required_fields!
    first(:link_or_button, 'Review and Submit').click
  end

  it 'sets the embargo end date' do
    expect(page).to have_content('Choose Publication Date')

    today_button = find_by_id('today_button')
    expect(today_button).to be_checked

    future_button = find_by_id('future_button')
    expect(future_button).not_to be_checked

    future_button.click

    end_date = Date.today + 3.months

    month_field = find_field_id('mmEmbargo')
    fill_in month_field, with: end_date.month

    day_field = find_field_id('ddEmbargo')
    fill_in day_field, with: end_date.day

    year_field = find_field_id('yyyyEmbargo')
    fill_in year_field, with: end_date.year

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
