require 'rails_helper'

RSpec.feature 'CurationActivity', type: :feature do

  include Mocks::Stripe

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
        # Create a user, identifier and 2 resources for each tenant
        ['ucop', 'dryad'].each do |tenant|
          user = create(:user, tenant_id: tenant)
          2.times.each do |i|
            identifier = create(:identifier)
            create(:resource, :submitted, user: user, identifier: identifier)
          end
        end
      end

      it 'admins can only see datasets for their tenant' do
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(2)
      end

      it 'super users can see all datasets' do
        sign_in(create(:user, role: 'superuser'))
        visit dashboard_path
        expect(all('.c-lined-table__row').length).to eql(4)
      end

    end

    context :in_progress_datasets do

      before(:each) do
        mock_stripe!
        create(:resource, user: create(:user, tenant_id: 'ucop'), identifier: create(:identifier))
        sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      end

      it 'do not have any "edit" pencil icons' do
        visit dashboard_path
        within(:css, '.c-lined-table__row') do
          expect(all('.fa-pencil').length).to eql(0)
        end
      end

      it 'have a "history" clock icon to view the activity log' do
        visit dashboard_path
        within(:css, '.c-lined-table__row') do
          expect(all('.fa-clock-o').length).to eql(1)
        end
      end

    end

  end

end
