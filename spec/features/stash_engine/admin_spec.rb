require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'Admin', type: :feature do

  before(:each) do
    @user = create(:user, role: 'admin')
    sign_in
  end

  context :security do

    it 'has admin link' do
      visit('/')
      expect(page).to have_link('Admin')
    end

  end

  it 'shows users for institution' do
    visit('/stash/admin')
    expect(page).to have_link('Leroy Jones')
  end

  it "shows a user's activity page" do
    visit('/stash/admin/user_dashboard/2')
    expect(page).to have_text("Leroy Jones's Activity")
    expect(page).to have_link('Evaluating Linked Lists')
  end

  it "shows a user's version history for a dataset" do
    visit('/stash/edit_histories?resource_id=1')
    expect(page).to have_text('1 (In Progress)')
    expect(page).to have_text('1 (Submitted)')
  end

  it 'allows editing a dataset' do
    visit('/stash/admin/user_dashboard/1')
    expect(page).to have_css('button.c-admin-edit-icon')
    first('button.c-admin-edit-icon').click

    wait_for_ajax!
    expect(page).to have_text("You are editing Mary McCormick's dataset.")

    click_link('Review and Submit')
    wait_for_ajax!
    expect(page).to have_css('input#user_comment')
  end

  describe 'superuser' do

    before(:each) do
      user = StashEngine::User.where(orcid: '555555555555555555555').first
      user.update(role: 'superuser')
      user.reload
    end

    it 'allows changing user role as a superuser' do
      visit('/stash/admin')
      wait_for_ajax!

      expect(page).to have_link('Leroy Jones')
      first('button.c-admin-edit-icon').click
      wait_for_ajax!

      expect(page).to have_css('input#role_admin')
      first('input#role_admin').click
      within(:css, 'div.o-admin-dialog') do
        find('input[name=commit]').click
      end
      wait_for_ajax!

      expect(page.find('#user_role_2')).to have_text('Admin')
    end
  end

end
# rubocop:enable Metrics/BlockLength
