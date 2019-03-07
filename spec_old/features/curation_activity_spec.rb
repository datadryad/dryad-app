require 'features_helper'

describe 'curation_activity' do
  fixtures :stash_engine_users, :stash_engine_resources, :stash_engine_identifiers,
           :stash_engine_resource_states, :stash_engine_curation_activities,
           :stash_engine_versions, :stash_engine_authors

  before(:each) do
    log_in!
    @user = StashEngine::User.find_by(orcid: '555555555555555555555')
  end

  context :admin_dashboard_security do

    it 'is not accessible by regular users' do
      @user.update(role: 'user')
      visit('/stash/ds_admin')
      # User should be redirected to the My Datasets page
      expect(page).to have_text('My Datasets')
    end

    it 'is accessible by admins' do
      @user.update(role: 'admin')
      visit('/stash/ds_admin')
      expect(page).to have_text('Admin Dashboard')
    end

    it 'is accessible by super users' do
      @user.update(role: 'superuser')
      visit('/stash/ds_admin')
      expect(page).to have_text('Admin Dashboard')
    end

    it 'admins can only see datasets for their tenant' do
      @user.update(role: 'admin', tenant_id: 'localhost')
      visit('/stash/ds_admin')
      expect(all('.c-lined-table__row').length).to eql(4)
    end

    it 'super users can see all datasets' do
      @user.update(role: 'superuser')
      visit('/stash/ds_admin')
      expect(all('.c-lined-table__row').length).to eql(5)
    end

  end

  context :in_progress_datasets do

    before(:each) do
      @user.update(role: 'superuser')
      @resource = StashEngine::Resource.where(current_curation_activity_id: 1).first
      visit('/stash/ds_admin')
      find('#curation_status').find('option[value="in_progress"]').select_option
    end

    it 'does not have any "edit" pencil icons' do

puts "RESOURCE: #{@resource.inspect}"
puts "CURATION_ACTIVITY: #{@resource.current_curation_activity.inspect}"
puts "LATEST RESOURCES: #{StashEngine::Resource.latest_per_dataset.pluck(&:id).inspect}"

      within(:css, '.c-lined-table__row:first-child') do
        expect(all('.fa-pencil').length).to eql(0)
      end
    end

    it 'does have an "history" clock icon to view the activity log' do
      within(:css, '.c-lined-table__row:first-child') do
        expect(all('.fa-clock-o').length).to eql(1)
      end
    end

  end

end