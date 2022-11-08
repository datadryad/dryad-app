require 'rails_helper'
# require 'pry-remote'

RSpec.feature 'CurationActivity', type: :feature do
  include Mocks::Aws
  include Mocks::Stripe
  include Mocks::Tenant
  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Datacite

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
        expect(page).to have_text('Admin dashboard')
      end

      it 'is accessible by curators' do
        sign_in(create(:user, role: 'curator', tenant_id: 'ucop'))
        visit dashboard_path
        expect(page).to have_text('Admin dashboard')
      end

      it 'is accessible by super users' do
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit dashboard_path
        expect(page).to have_text('Admin dashboard')
      end

    end

    context :content do

      before(:each) do
        mock_stripe!
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

      it 'lets curators see all datasets' do
        sign_in(create(:user, role: 'curator'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(6)
      end

      it 'has ajax showing counter stats and citations', js: true do
        sign_in(create(:user, role: 'curator', tenant_id: 'ucop'))
        visit dashboard_path
        el = find('td', text: @identifiers.first.resources.first.title)
        el = el.first(:xpath, './following-sibling::td').find(:css, '.js-stats')
        el.click
        my_stats = @identifiers.first.counter_stat
        page.first :css, '.o-metrics__icon'
        expect(page).to have_content("#{my_stats.citation_count} citations")
        expect(page).to have_content("#{my_stats.views} views")
        expect(page).to have_content("#{my_stats.downloads} downloads")
      end

      it 'generates a csv having dataset information with citations, views and downloads' do
        sign_in(create(:user, role: 'curator', tenant_id: 'ucop'))
        visit dashboard_path
        click_link('Get Comma Separated Values (CSV) for import into Excel')

        title = @identifiers.first.resources.first.title
        my_stats = @identifiers.first.counter_stat

        csv_line = page.body.split("\n").select { |i| i.start_with?(title) }.first
        csv_parts = csv_line.split(',')

        expect(csv_parts[-4].to_i).to eql(my_stats.views)
        expect(csv_parts[-3].to_i).to eql(my_stats.downloads)
        expect(csv_parts[-2].to_i).to eql(my_stats.citation_count)
      end

      it 'generates a csv that includes submitter institutional name' do
        sign_in(create(:user, role: 'curator', tenant_id: 'ucop'))
        visit dashboard_path
        click_link('Get Comma Separated Values (CSV) for import into Excel')

        title = @identifiers.first.resources.first.title

        csv_line = page.body.split("\n").select { |i| i.start_with?(title) }.first
        csv_parts = csv_line.split(',')

        expect(csv_parts[-1]).to eql(@identifiers.first.resources.first.tenant.long_name)
      end

    end

    context :in_progress_datasets do

      before(:each) do
        mock_stripe!
        mock_solr!
        mock_repository!
        mock_datacite_and_idgen!

        create(:resource, user: create(:user, tenant_id: 'ucop'), identifier: create(:identifier))
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
        visit "#{dashboard_path}?curation_status=in_progress"
      end

      it 'does not have any "edit" pencil icons' do
        within(:css, '.c-lined-table__row') do
          expect(all('.fa-pencil').length).to eql(0)
        end
      end

      it 'has a "history" clock icon to view the activity log' do
        within(:css, '.c-lined-table__row') do
          expect(all('.fa-clock-o').length).to eql(1)
        end
      end

    end

    context :curating_dataset, js: true do

      before(:each) do
        mock_aws!
        mock_salesforce!
        mock_stripe!
        mock_repository!
        mock_datacite_and_idgen!
        @user = create(:user, tenant_id: 'ucop')
        @resource = create(:resource, user: @user, identifier: create(:identifier), skip_datacite_update: true)
        create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
        @resource.resource_states.first.update(resource_state: 'submitted')
        sign_in(create(:user, role: 'curator', tenant_id: 'ucop'))
        visit "#{dashboard_path}?curation_status=curation"
      end

      it 'submits a curation status changes and reflects in the page and history afterwards' do
        within(:css, '.c-lined-table__row', wait: 10) do
          find('button[title="Update status"]').click
        end

        # select the author action required

        find("#stash_engine_resource_curation_activity_status option[value='action_required']").select_option

        # fill in a note
        fill_in(id: 'stash_engine_resource_curation_activity_note', with: 'My cat says hi')
        click_button('Submit')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Author Action Required')
          find('button[title="View Activity Log"]').click
        end

        expect(page).to have_text('My cat says hi')
      end

      it 'renders salesforce links in notes field' do
        @curation_activity = create(:curation_activity, note: 'Not a valid SF link', resource: @resource)
        @curation_activity = create(:curation_activity, note: 'SF #0001 does not exist', resource: @resource)
        @curation_activity = create(:curation_activity, note: 'SF #0002 should exist', resource: @resource)
        within(:css, '.c-lined-table__row', wait: 10) do
          find('button[title="View Activity Log"]').click
        end
        expect(page).to have_text('Activity Log for')
        expect(page).to have_text('Not a valid SF link')
        # 'SF #0001' is not a valid case number, so the text is not changed
        expect(page).to have_text('SF #0001')
        # 'SF #0002' should be turned into a link with the caseID 'abc',
        # and the '#' dropped to display the normalized form of the case number
        expect(page).to have_link('SF 0002', href: 'https://testsalesforce.com/lightning/r/Case/abc/view')
      end

      it 'renders salesforce section' do
        within(:css, '.c-lined-table__row', wait: 10) do
          find('button[title="View Activity Log"]').click
        end
        expect(page).to have_text('Activity log for')
        expect(page).to have_text('Salesforce Cases')
        expect(page).to have_link('SF 0003', href: 'https://dryad.lightning.force.com/lightning/r/Case/abc1/view')
      end

      it 'allows curation editing of users dataset and returning to admin list in same state afterward' do
        # the button to edit has this class on it
        find('.js-trap-curator-url').click
        all('[id^=instit_affil_]').last.set('test institution')
        add_required_data_files
        navigate_to_review
        agree_to_everything
        fill_in 'user_comment', with: Faker::Lorem.sentence
        submit = find_button('submit_dataset', disabled: :all)
        submit.click
        expect(URI.parse(current_url).request_uri).to eq("#{dashboard_path}?curation_status=curation")
      end

      it 'allows curation editing and aborting editing of user dataset and return to list in same state afterward' do
        # the button to edit has this class on it
        find('.js-trap-curator-url').click

        expect(page).to have_field('Dataset Title') # so it waits for actual ajax doc to load before doing anything else

        click_on('Cancel and Discard Changes')
        find('#railsConfirmDialogYes').click
        expect(URI.parse(current_url).request_uri).to eq("#{dashboard_path}?curation_status=curation")
      end
    end
  end
end
