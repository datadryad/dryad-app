require 'rails_helper'
# require 'pry-remote'

RSpec.feature 'CurationActivity', type: :feature do

  include Mocks::Stripe
  include Mocks::Ror
  include Mocks::Tenant

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
        mock_tenant!

        # Create a user, identifier and 2 resources for each tenant
        %w[ucop dryad mock_tenant].each do |tenant|
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
        sign_in(create(:user, role: 'admin', tenant_id: 'mock_tenant'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(2)
      end

      it 'lets superusers see all datasets' do
        sign_in(create(:user, role: 'superuser'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(6)
      end

      it 'has ajax showing counter stats and citations', js: true do
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit dashboard_path
        el = find('td', text: @identifiers.first.resources.first.title)
        el = el.first(:xpath, './following-sibling::td').find(:css, '.js-stats')
        el.click
        my_stats = @identifiers.first.counter_stat
        page.first :css, '.o-metrics__icon', wait: 10
        expect(page).to have_content("#{my_stats.citation_count} citations")
        expect(page).to have_content("#{my_stats.views} views")
        expect(page).to have_content("#{my_stats.downloads} downloads")
      end

      it 'generates a csv having dataset information with citations, views and downloads' do
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit dashboard_path
        click_link('Get Comma Separated Values (CSV) for import into Excel')

        title = @identifiers.first.resources.first.title
        my_stats = @identifiers.first.counter_stat

        csv_line = page.body.split("\n").select { |i| i.start_with?(title) }.first
        csv_parts = csv_line.split(',')

        expect(csv_parts[-3].to_i).to eql(my_stats.views)
        expect(csv_parts[-2].to_i).to eql(my_stats.downloads)
        expect(csv_parts[-1].to_i).to eql(my_stats.citation_count)
      end

    end

    context :in_progress_datasets do

      before(:each) do
        mock_stripe!
        mock_ror!

        create(:resource, user: create(:user, tenant_id: 'ucop'), identifier: create(:identifier))
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
        visit "#{dashboard_path}?curation_status=in_progress"
      end

      it 'does not have any "edit" pencil icons' do
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

    context :curating_dataset, js: true do

      before(:each) do
        mock_stripe!
        mock_ror!
        @user = create(:user, tenant_id: 'ucop')
        @resource = create(:resource, user: @user, identifier: create(:identifier), skip_datacite_update: true)
        create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
        @resource.resource_states.first.update(resource_state: 'submitted')
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit "#{dashboard_path}?curation_status=curation"
      end

      it 'submits a curation status changes and reflects in the page and history afterwards' do
        within(:css, '.c-lined-table__row', wait: 10) do
          all(:css, 'button')[2].click
        end

        # select the author action required
        find("#resource_curation_activity_status option[value='action_required']").select_option

        # fill in a note
        fill_in(id: 'resource_curation_activity_note', with: 'My cat says hi')
        click_button('Submit')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Author Action Required')
          all(:css, 'button').last.click
        end

        expect(page).to have_text('My cat says hi')
      end

    end

  end

end
