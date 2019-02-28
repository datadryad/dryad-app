require 'features_helper'

describe 'tenant variations' do

  fixtures :stash_engine_users

  describe 'Logos' do

    StashEngine.tenants.each_value do |hash|
      it "shows correct logo for #{hash[:short_name]}" do
        log_in!
        @user = StashEngine::User.last
        @user.update(tenant_id: hash[:tenant_id])

        visit(root_path)

p page.body

        expect(page).to have_css('img[alt="Dryad logo"]') # Expect the Dryad logo always!
        expect(page).to have_css("img[alt=\"#{hash[:short_name]} logo\"]") unless hash[:tenant_id] == 'localhost'
      end
    end

  end

end
