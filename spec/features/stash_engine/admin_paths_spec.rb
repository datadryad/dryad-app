RSpec.feature 'AdminPaths', type: :feature do
  include Mocks::Salesforce

  before(:each) do
    create(:tenant)
  end

  context :admin_dashboard_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.admin_dashboard_path
      # User should be redirected to the My datasets page
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.admin_dashboard_path
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.admin_dashboard_path
      expect(page).to have_text('Admin dashboard')
    end
  end

  context :curation_activity_path do
    before(:each) do
      mock_salesforce!
      @user = create(:user)
      @dataset = create(:resource, user: @user)
      @path = stash_url_helpers.url_for(controller: '/stash_engine/admin_datasets', action: 'index',
                                        id: @dataset.identifier_id, only_path: true)
    end

    it 'is not accessible by regular users' do
      sign_in(@user)
      visit @path
      # User should be redirected to the My datasets page
      expect(page).to have_text('My datasets')
    end

    it 'is accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit @path
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text(@dataset.title.to_s)
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit @path
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text(@dataset.title.to_s)
    end
  end

  context :curation_stats_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.curation_stats_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.curation_stats_path
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.curation_stats_path
      expect(page).to have_text('Recent statistics are available in the table below')
    end
  end

  context :journals_path do
    it 'is not fully accessibile by regular users' do
      sign_in
      visit stash_url_helpers.journals_path
      expect(page).to have_text('Journals')
      expect(page).not_to have_text('Payment plan')
    end

    it 'is not fully accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.journals_path
      expect(page).to have_text('Journals')
      expect(page).not_to have_text('Payment plan')
    end

    it 'is not fully accessible by tenant curators' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'curator', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.journals_path
      expect(page).to have_text('Journals')
      expect(page).not_to have_text('Payment plan')
    end

    it 'is fully accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.journals_path
      expect(page).to have_text('Journals')
      expect(page).to have_text('Payment plan')
    end
  end

  context :pub_updater_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.publication_updater_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.publication_updater_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by dryad admins' do
      sign_in(create(:user,  role: 'admin'))
      visit stash_url_helpers.publication_updater_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by curators' do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_text('Publication updater')
    end

    it 'is accessible by tenant curators' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'curator', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_text('Publication updater')
    end

    it 'is accessible by data managers' do
      sign_in(create(:user, role: 'manager'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_text('Publication updater')
    end

    it 'is accessible by super users' do
      sign_in(create(:user, role: 'superuser'))
      visit stash_url_helpers.publication_updater_path
      expect(page).to have_text('Publication updater')
    end
  end

  context :user_admin_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.user_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.user_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by tenant curators' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'curator', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.user_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.user_admin_path
      expect(page).to have_text('Manage users')
    end
  end

  context :tenant_admin_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.tenant_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.tenant_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by tenant curators' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'curator', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.tenant_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.tenant_admin_path
      expect(page).to have_text('Manage partner institutions')
    end
  end

  context :journal_admin_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.journal_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.journal_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by tenant curators' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'curator', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.journal_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.journal_admin_path
      expect(page).to have_text('Manage journals')
    end
  end

  context :journal_org_admin_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.publisher_admin_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.publisher_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by tenant curators' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'curator', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.publisher_admin_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by dryad admins' do
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.publisher_admin_path
      expect(page).to have_text('Manage publishers')
    end
  end

  context :status_dashboard_path do
    it 'is not accessible by regular users' do
      sign_in
      visit stash_url_helpers.status_dashboard_path
      # User redirected
      expect(page).to have_text('My datasets')
    end

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.status_dashboard_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by data managers' do
      sign_in(create(:user, role: 'manager'))
      visit stash_url_helpers.status_dashboard_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by super users', js: true do
      create(:external_dependency)
      sign_in(create(:user, role: 'superuser'))
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

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.submission_queue_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by curators' do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.submission_queue_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by data managers', js: true do
      sign_in(create(:user, role: 'manager'))
      visit stash_url_helpers.submission_queue_path
      expect(page).to have_text('Queue information')
    end

    it 'is accessible by super users', js: true do
      sign_in(create(:user, role: 'superuser'))
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

    it 'is not accessible by tenant admins' do
      tenant = create(:tenant_ucop)
      sign_in(create(:user, role: 'admin', role_object: tenant, tenant_id: 'ucop'))
      visit stash_url_helpers.zenodo_queue_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by curators' do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.zenodo_queue_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is not accessible by data managers' do
      sign_in(create(:user, role: 'manager'))
      visit stash_url_helpers.zenodo_queue_path
      # User redirected
      expect(page).to have_text('Admin dashboard')
    end

    it 'is accessible by super users' do
      sign_in(create(:user, role: 'superuser'))
      visit stash_url_helpers.zenodo_queue_path
      expect(page).to have_text('Zenodo submission queue')
    end
  end

end
