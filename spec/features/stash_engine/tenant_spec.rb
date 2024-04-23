require 'rails_helper'

RSpec.feature 'Tenant', type: :feature do

  context :logos do
    it 'displays the correct logo for UCOP' do
      create(:tenant)
      @user = create(:user, tenant_id: 'ucop')
      sign_in(@user)
      visit root_path
      # Always expect to see the Dryad logo
      expect(page).to have_css('img[alt="Dryad"]')
      expect(page).to have_css("img[alt=\" #{@user.tenant.short_name}\"]")
    end
  end
end
