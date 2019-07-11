require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'Admin', type: :feature do

  include Mocks::Stripe
  include Mocks::Ror
  include Mocks::RSolr

  before(:each) do
    @admin = create(:user, role: 'admin', tenant_id: 'ucop')
  end

  context :user_dashboard do

    before(:each) do
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      mock_solr!
      mock_stripe!
      mock_ror!
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier)
      sign_in(@admin)
    end

    it 'has admin link' do
      visit root_path
      expect(page).to have_link('Admin')
    end

    it 'shows users for institution' do
      visit stash_url_helpers.admin_path
      expect(page).to have_link(@user.name)
    end

    it "shows a user's activity page" do
      visit stash_url_helpers.admin_user_dashboard_path(@user)
      expect(page).to have_text("#{@user.name}'s Activity")
      expect(page).to have_css("[href$='resource_id=#{@resource.id}']")
    end

    it "shows a user's version history for a dataset" do
      visit stash_url_helpers.edit_histories_path(resource_id: @resource.id)
      expect(page).to have_text('1 (Submitted)')
    end

    it 'allows editing a dataset', js: true do
      visit stash_url_helpers.admin_user_dashboard_path(@user)
      expect(page).to have_css('button[title="Edit Dataset"]')
      find('button[title="Edit Dataset"]').click
      expect(page).to have_text("You are editing #{@user.name}'s dataset.", wait: 15)
      click_link 'Review and Submit'
      expect(page).to have_css('input#user_comment', wait: 15)
    end

    context :superuser do

      before(:each) do
        @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
        sign_in(@superuser)
      end

      it 'has admin link' do
        visit root_path
        find('.o-sites__summary', text: 'Admin').click
        expect(page).to have_link('Dataset Curation', wait: 5)
        expect(page).to have_link('Publication Updater')
        expect(page).to have_link('Status Dashboard')
        expect(page).to have_link('Submission Queue')
      end

      it 'allows changing user role as a superuser', js: true do
        visit stash_url_helpers.admin_path
        expect(page).to have_link(@user.name)
        within(:css, "form[action=\"#{stash_url_helpers.popup_admin_path(@user.id)}\"]") do
          find('.c-admin-edit-icon').click
        end
        within(:css, 'div.o-admin-dialog', wait: 5) do
          find('#role_admin').set(true)
          find('input[name=commit]').click
        end
        expect(page.find("#user_role_#{@user.id}")).to have_text('Admin', wait: 5)
      end
    end

  end

end
# rubocop:enable Metrics/BlockLength
