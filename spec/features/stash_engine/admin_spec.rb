require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'Admin', type: :feature do

  before(:each) do
    @admin = create(:user, role: 'admin', tenant_id: 'ucop')
    sign_in(@admin)
  end

  context :security do
    it 'has admin link' do
      visit root_path
      expect(page).to have_link('Admin')
    end

  end

  context :user_dashboard do

    before(:each) do
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource)
    end

    it 'shows users for institution' do
      visit admin_path
      expect(page).to have_link(@user.name)
    end

    it "shows a user's activity page" do
      visit admin_user_dashboard_path(@user)
      expect(page).to have_text("#{@user.name}'s Activity")
      expect(page).to have_link('Evaluating Linked Lists')
    end

    it "shows a user's version history for a dataset" do
      resource = create(:resource, :submitted, identifier: @identifier, user: @user)

p @user.inspect
p @identifier.inspect
p @identifier.resources.length

p resource.inspect
p resource.current_resource_state_id
p resource.resource_states.inspect
p resource.current_curation_activity_id
p resource.curation_activities.inspect

      #visit('/stash/edit_histories?resource_id=1')
      #expect(page).to have_text('1 (In Progress)')
      #expect(page).to have_text('1 (Submitted)')
    end

    it 'allows editing a dataset' do
      #visit('/stash/admin/user_dashboard/1')
      #expect(page).to have_css('button.c-admin-edit-icon')
      #first('button.c-admin-edit-icon').click

      #wait_for_ajax!
      #expect(page).to have_text("You are editing Mary McCormick's dataset.")

      #click_link('Review and Submit')
      #wait_for_ajax!
      #expect(page).to have_css('input#user_comment')
    end

    context :superuser do

      before(:each) do
        @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
      end

      it 'allows changing user role as a superuser' do
        visit admin_path
        expect(page).to have_link(@user.name)
        click_link 'button.c-admin-edit-icon'
        expect(page).to have_css('input#role_admin', wait: 5)
        first('input#role_admin').click
        within(:css, 'div.o-admin-dialog') do
          find('input[name=commit]').click
        end
        expect(page.find('#user_role_2')).to have_text('Admin', wait: 5)
      end
    end

  end

end
# rubocop:enable Metrics/BlockLength
