require 'rails_helper'
RSpec.feature 'CurationActivity', type: :feature do

  include Mocks::Stripe
  include Mocks::Ror

  # TODO: This should probably be defined in routes.rb and have appropriate helpers
  let(:dashboard_path) { '/stash/ds_admin' }

  context :dashboard_security do

    context :access do

      it 'is not accessible by regular users' do
        sign_in
        visit dashboard_path
        # User should be redirected to the My Datasets page
        expect(page).to have_text('My Datasets')
      end

      it 'is accessible by admins' do
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
        visit dashboard_path
        expect(page).to have_text('Admin Dashboard')
      end

      it 'is accessible by super users' do
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit dashboard_path
        expect(page).to have_text('Admin Dashboard')
      end

    end

    context :content do

      before(:each) do
        mock_stripe!
        mock_ror!
        # Create a user, identifier and 2 resources for each tenant
        %w[ucop dryad].each do |tenant|
          user = create(:user, tenant_id: tenant)
          @identifiers = []
          2.times.each do
            identifier = create(:identifier)
            create(:resource, :submitted, user: user, identifier: identifier)
            cite_number = rand(4)
            cite_number.times { create(:counter_citation, identifier: identifier) }
            create(:counter_stat, citation_count: cite_number, identifier: identifier)
            @identifiers.push(identifier)
          end
        end
      end

      it 'shows admins datasets for their tenant' do
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(2)
      end

      it 'lets superusers see all datasets' do
        sign_in(create(:user, role: 'superuser'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(4)
      end

      it 'has ajax showing counter stats and citations', js: true do
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit dashboard_path
        el = find('td', text: @identifiers.first.resources.first.title)
        el = el.first(:xpath, './following-sibling::td').find(:css, '.js-stats')
        el.click
        my_stats = @identifiers.first.counter_stat
        page.first :css, '.o-metrics__icon', wait: 10
        page.should have_content("#{my_stats.citation_count} citations")
        page.should have_content("#{my_stats.unique_investigation_count - my_stats.unique_request_count} views")
        page.should have_content("#{my_stats.unique_request_count} downloads")
      end

    end

    context :in_progress_datasets do

      before(:each) do
        mock_stripe!
        mock_ror!
        create(:resource, user: create(:user, tenant_id: 'ucop'), identifier: create(:identifier))
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
        visit "#{dashboard_path}?curation_status=in_progress"
        # find('#curation_status').select('In Progress')
      end

      it 'do not have any "edit" pencil icons' do
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(all('.fa-pencil').length).to eql(0)
        end
      end

      it 'has a "history" clock icon to view the activity log' do
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(all('.fa-clock-o').length).to eql(1)
        end
      end

    end

  end

end
