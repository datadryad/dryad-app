require 'pry-remote'

RSpec.feature 'AdminPaths', type: :feature do
  include Mocks::CurationActivity
  include Mocks::Salesforce

  context :admin_datasets_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.ds_admin_path
      # User should be redirected to the My datasets page
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.ds_admin_path
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by limited_curators' do
      sign_in(create(:user, role: 'limited_curator', tenant_id: 'dryad'))
      visit stash_url_helpers.ds_admin_path
      expect(page).to have_text('Admin dashboard')
    end
  end

  context :curation_activity_path do
    before(:each) do
      mock_salesforce!
      @user = create(:user)
      @dataset = create(:resource, user: @user)
      @path = stash_url_helpers.url_for(controller: '/stash_engine/admin_datasets', action: 'activity_log',
                                        id: @dataset.identifier_id, only_path: true)
    end

    it 'is not accessible by regular users' do
      sign_in(@user)
      visit @path
      # User should be redirected to the My datasets page
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit @path
      expect(page).to have_text("Activity log for #{@dataset.title}")
    end

    it 'is accessible by limited_curators' do
      sign_in(create(:user, role: 'limited_curator', tenant_id: 'dryad'))
      visit @path
      expect(page).to have_text("Activity log for #{@dataset.title}")
    end
  end

  context :curation_stats_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.curation_stats_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.curation_stats_path
      expect(page).to have_text('Curation stats table')
    end

    it 'is accessible by limited_curators' do
      sign_in(create(:user, role: 'limited_curator', tenant_id: 'dryad'))
      visit stash_url_helpers.curation_stats_path
      expect(page).to have_text('Curation stats table')
    end
  end

  context :journals_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.journals_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.journals_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by curators' do
      sign_in(create(:user, role: 'limited_curator', tenant_id: 'dryad'))
      visit stash_url_helpers.journals_path
      expect(page).to have_text('Journals')
    end
  end

  context :pub_updater_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.publication_updater_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.publication_updater_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by limited_curators' do
      sign_in(create(:user, role: 'limited_curator', tenant_id: 'ucop'))
      visit stash_url_helpers.publication_updater_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by curators' do
      sign_in(create(:user, role: 'curator', tenant_id: 'dryad'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_text('Publication updater')
    end

    it 'is accessible by super users' do
      sign_in(create(:user, role: 'superuser', tenant_id: 'dryad'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_text('Publication updater')
    end
  end

  context :dataset_funder_path do
    before(:each) do
      mock_salesforce!
      neuter_curation_callbacks!
      user = create(:user, tenant_id: 'ucop')
      resource = create(:resource, user: user, tenant_id: 'ucop')
      create(:curation_activity_no_callbacks, status: 'published', user_id: user.id, resource_id: resource.id)
    end
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.ds_admin_funders_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.ds_admin_funders_path
      expect(page).to have_text('Dataset funder dashboard')
    end

    it 'is accessible by limited_curators' do
      sign_in(create(:user, role: 'limited_curator', tenant_id: 'dryad'))
      visit stash_url_helpers.ds_admin_funders_path
      expect(page).to have_text('Dataset funder dashboard')
    end
  end

  context :user_admin_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.user_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.user_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by curators' do
      sign_in(create(:user, role: 'curator', tenant_id: 'dryad'))
      visit stash_url_helpers.user_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by super users' do
      sign_in(create(:user, role: 'superuser', tenant_id: 'dryad'))
      visit stash_url_helpers.user_admin_path
      expect(page).to have_text('Manage users')
    end
  end

  context :status_dashboard_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.status_dashboard_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.status_dashboard_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by curators' do
      sign_in(create(:user, role: 'curator', tenant_id: 'dryad'))
      visit stash_url_helpers.status_dashboard_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by super users', js: true do
      create(:external_dependency)
      sign_in(create(:user, role: 'superuser', tenant_id: 'dryad'))
      visit stash_url_helpers.status_dashboard_path
      expect(page).to have_text('External dependency statuses')
    end
  end

  context :submission_queue_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.submission_queue_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.submission_queue_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by curators' do
      sign_in(create(:user, role: 'curator', tenant_id: 'dryad'))
      visit stash_url_helpers.submission_queue_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by super users', js: true do
      sign_in(create(:user, role: 'superuser', tenant_id: 'dryad'))
      visit stash_url_helpers.submission_queue_path
      expect(page).to have_text('Queue information')
    end
  end

  context :zenodo_queue_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.zenodo_queue_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by admins' do
      sign_in(create(:user, role: 'admin', tenant_id: 'ucop'))
      visit stash_url_helpers.zenodo_queue_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by curators' do
      sign_in(create(:user, role: 'curator', tenant_id: 'dryad'))
      visit stash_url_helpers.zenodo_queue_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by super users' do
      sign_in(create(:user, role: 'superuser', tenant_id: 'dryad'))
      visit stash_url_helpers.zenodo_queue_path
      expect(page).to have_text('Zenodo submission queue')
    end
  end

end
