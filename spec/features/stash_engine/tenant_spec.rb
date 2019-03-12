require 'rails_helper'

RSpec.feature 'Tenant', type: :feature do

  context :logos do

    StashEngine.tenants.each_value do |hash|
      it "displays the correct logo for #{hash[:short_name]}" do
        sign_in(create(:user, tenant_id: hash[:tenant_id]))
        visit root_path
        # Always expect to see the Dryad logo
        expect(page).to have_css('img[alt="Dryad logo"]')
        # If the tenant_id is not dryad or localhost then expect to
        # see the institution's logo
        unless %w[localhost dryad].include?(hash[:tenant_id])
          expect(page).to have_css("img[alt=\"#{hash[:short_name]} logo\"]")
        end
      end
    end

  end

end
