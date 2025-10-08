Rails.application.routes.draw do
  constraints(:host => /datadryad.com/) do
    match "/(*path)" => redirect {|params, req| "https://datadryad.org/#{params[:path]}"},  via: [:get, :post]
  end
  match '(*any)', to: redirect(subdomain: ''), via: :all, constraints: {subdomain: 'www'}
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  use_doorkeeper
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rails routes".

  # root :requirements => { :protocol => 'http' }, :to => redirect(path: '/' )

  root to: 'stash_engine/pages#home'

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.dev?

  # this is a rack way of showing a 404 for some crazy old/speculative link that Google has stuck in its craw
  get '/search/facet/dc_creator_sm', to: proc { [410, {}, ['']] }

  get 'xtf/search', :to => redirect { |params, request| "/search?#{request.params.to_query}" }

  # This will route an item at the root of the site into the namespaced engine.
  # However it is currently broken, so commented out until we fix it.
  get 'sitemap.xml' => "stash_engine/pages#sitemap", :format => "xml", :as => 'sitemap'

  # routing this into the engine since that is where we have all our models and curation state info which we need
  get 'widgets/bannerForPub' => 'stash_engine/widgets#banner_for_pub'
  get 'widgets/dataPackageForPub' => 'stash_engine/widgets#data_package_for_pub'

  # react test
  get 'react' => 'react_test#index'

  # Individual pages that we're redirecting from the old wiki, then a catchall
  # for any other page from the old wiki. The individual pages must be listed
  # first, or they will not take effect.
  get '/Governance', to: redirect('/about#our-board')
  get '*path',
      constraints: {host: 'wiki.datadryad.org'},
      to: redirect('https://github.com/datadryad/dryad-app/tree/main/documentation/v1_wiki_content.md')

  ############################# API support ######################################

  scope module: 'stash_api', path: '/api/v2' do
    # StashApi::GeneralController#index
    get '/', to: 'api#index'
    match '/test', to: 'api#test', via: %i[get post]
    match '/search', to: 'datasets#search', via: %i[get]
    get '/reports', to: 'api#reports_index'
    get '/reports(/:report_name)', to: 'api#reports'

    # Support for the Editorial Manager API
    match '/em_submission_metadata(/:id)', constraints: { id: /\S+/ }, to: 'datasets#em_submission_metadata', via: %i[post put]

    resources :datasets, shallow: true, id: %r{[^\s/]+?}, format: /json|xml|yaml/, path: '/datasets' do
      member do
        get 'download'
        post 'set_internal_datum'
        post 'add_internal_datum'
        get 'calculate_fee'
      end
      resources :related_works, shallow: false, only: 'update'
      resources :internal_data, shallow: true, path: '/internal_data'
      resources :curation_activity, shallow: false, path: '/curation_activity'

      resources :versions, shallow: true, path: '/versions' do
        get 'download', on: :member
        get 'zip_assembly(/:token)', token: %r{[^\s/]+?}, to: 'versions#zip_assembly', as: 'zip_assembly'
        resources :files, shallow: true, path: '/files' do
          get :download, on: :member
          resource :frictionless_report, path: '/frictionlessReport'
          resource :sensitive_data_report, path: '/sensitiveDataReport', only: %i[show create update]
        end
        resources :processor_results, only: [:show, :index, :create, :update]
      end

      resources :urls, shallow: true, path: '/urls', only: [:create]
    end

    # this one doesn't follow the pattern since it gloms filename on the end, so manual route
    # supporting both POST and PUT for updating the file to ensure as many clients as possible can use this end point
    match '/datasets/:id/files/:filename', to: 'files#update', as: 'dataset_file', constraints: { id: %r{[^\s/]+?}, filename: %r{[^\s/]+?} }, format: false, via: %i[post put]

    get '/queue_length', to: 'submission_queue#length'
  end

  ########################## StashEngine support ######################################

  scope module: 'stash_engine' do

    get 'landing/show'

    resources :resources do
      member do
        get 'prepare_readme'
        get 'display_readme'
        get 'dpc_status'
        get 'dupe_check'
        get 'file_pub_dates'
        get 'display_collection'
        get 'show_files'
        patch 'import_type'
        patch 'license_agree'
        post 'logout'
        get :payer_check
      end
    end

    resources :identifiers do
      resources :internal_data, shallow: true, as: 'identifier_internal_data'
    end
    match 'identifier_internal_data/:identifier_id', to: 'internal_data#create', as: 'internal_data_create', via: %i[get post put]
    
    resources :internal_data, shallow: true, as: 'stash_engine_internal_data'
    resources :resource_publications, shallow: true, as: 'resource_publication'
    resources :tenants, only: %i[index show]

    resources :data_files, :software_files, :supp_files do
      member do
        patch 'destroy_manifest' # destroy file from manifest method
        patch 'rename'
        get 'frictionless_report'
        get 'sd_report'
      end
    end

    resources :edit_histories, only: [:index]

    # these are weird and different and want to get rid of these with file redesign
    match 'data_file/validate_urls/:resource_id', to: 'data_files#validate_urls', as: 'data_file_validate_urls', via: %i[get post put]
    match 'software_file/validate_urls/:resource_id', to: 'software_files#validate_urls', as: 'software_file_validate_urls', via: %i[get post put]
    match 'supp_file/validate_urls/:resource_id', to: 'supp_files#validate_urls', as: 'supp_file_validate_urls', via: %i[get post put]

    get 'data_file/presign_upload/:resource_id', to: 'data_files#presign_upload', as: 'data_file_presign_url'
    get 'software_file/presign_upload/:resource_id', to: 'software_files#presign_upload', as: 'software_file_presign_url'
    get 'supp_file/presign_upload/:resource_id', to: 'supp_files#presign_upload', as: 'supp_file_presign_url'
    # TODO: this is to be the replacement for the 3 above
    get 'generic_file/presign_upload/:resource_id', to: 'generic_files#presign_upload', as: 'generic_file_presign_url'

    get 'generic_file/check_frictionless/:resource_id', to: 'generic_files#check_frictionless', as: 'check_frictionless' 

    post 'data_file/upload_complete/:resource_id', to: 'data_files#upload_complete', as: 'data_file_complete'
    post 'software_file/upload_complete/:resource_id', to: 'software_files#upload_complete', as: 'software_file_complete'
    post 'supp_file/upload_complete/:resource_id', to: 'supp_files#upload_complete', as: 'supp_file_complete'    

    get 'software_license_select', to: 'software_files#licenses'
    get 'software_licenses', to: 'software_files#licenses_autocomplete'
    post 'software_license', to: 'software_files#license'

    get 'choose_dashboard', to: 'dashboard#choose', as: 'choose_dashboard'
    get 'dashboard', to: 'dashboard#show', as: 'dashboard'
    get 'dashboard/user_datasets', to: 'dashboard#user_datasets'
    get 'dashboard/primary_article/:resource_id', to: 'dashboard#primary_article', as: 'primary_article'
    get 'dashboard/contact_helpdesk/:id', to: 'dashboard#contact_helpdesk', as: 'contact_helpdesk_form'
    post 'dashboard/primary_article', to: 'dashboard#save_primary_article', as: 'save_primary_article'

    # download related
    match 'downloads/zip_assembly_info/:resource_id', to: 'downloads#zip_assembly_info', as: 'zip_assembly_info', via: %i[get post]
    match 'downloads/download_resource/:resource_id', to: 'downloads#download_resource', as: 'download_resource', via: %i[get post]
    match 'downloads/capture_email/:resource_id', to: 'downloads#capture_email', as: 'download_capture_email', via: %i[get post]
    get 'downloads/file_stream/:file_id', to: 'downloads#file_stream', as: 'download_stream'
    get 'downloads/zenodo_file/:file_id', to: 'downloads#zenodo_file', as: 'download_zenodo'
    get 'downloads/pre_submit/:file_id', to: 'downloads#presubmit_file_stream', as: 'download_presubmit'
    get 'downloads/:file_id/linkset', to: 'downloads#linkset', as: 'file_linkset'
    get 'data_file/preview_check/:file_id', to: 'downloads#preview_check', as: 'preview_check'
    get 'data_file/preview/:file_id', to: 'downloads#preview_file', as: 'preview_file'
    get 'share/:id', to: 'downloads#share'
    get 'share/LINK_NOT_FOR_PUBLICATION/:id', to: 'downloads#share', as: 'share'
    get 'downloads/assembly_status/:id', to: 'downloads#assembly_status', as: 'download_assembly_status'

    get 'edit/:doi/:edit_code', to: 'metadata_entry_pages#edit_by_doi', as: 'edit', constraints: { doi: /\S+/ }
    match 'submission/:resource_id', to: 'metadata_entry_pages#find_or_create', via: %i[get post put], as: 'metadata_entry_pages_find_or_create'
    match 'metadata_entry_pages/new_version', to: 'metadata_entry_pages#new_version', via: %i[post get]
    post 'metadata_entry_pages/new_version_from_previous', to: 'metadata_entry_pages#new_version_from_previous'
    match 'metadata_entry_pages/reject_agreement', to: 'metadata_entry_pages#reject_agreement', via: [:post]
    match 'metadata_entry_pages/accept_agreement', to: 'metadata_entry_pages#accept_agreement', via: [:post]

    get 'accept/:edit_code', to: 'edit_codes#accept_invite', as: 'accept_invite'

    # root 'sessions#index'
    root 'pages#home', as: 'pages_root'

    # this is temporary until we get ORCID configured
    match '/stash/auth/orcid/callback', to: 'sessions#orcid_callback', via: %i[get post]

    match 'auth/orcid/callback', to: 'sessions#orcid_callback', via: %i[get post]
    match 'auth/google_oauth2/callback', to: 'sessions#google_callback', via: %i[get post]
    match 'auth/developer/callback', to: 'sessions#developer_callback', via: %i[get post]
    match 'auth/:provider/callback', to: 'sessions#callback', via: %i[get post]
    match 'session/test_login', to: 'sessions#test_login', via: [:get, :post],  as: 'test_login'

    get 'auth/failure', to: redirect('/')
    match 'sessions/destroy', to: 'sessions#destroy', via: %i[get post]
    get 'sessions/choose_login', to: 'sessions#choose_login', as: 'choose_login'
    get 'sessions/choose_sso', to: 'sessions#choose_sso', as: 'choose_sso'
    get 'sessions/:tenant_id/email', to: 'sessions#email_sso', as: 'email_sso'
    post 'sessions/email_code', to: 'sessions#validate_sso_email', as: 'validate_sso_email'
    match 'sessions/no_partner', to: 'sessions#no_partner', as: 'no_partner', via: [:get, :post]
    post 'sessions/sso', to: 'sessions#sso', as: 'sso'
    get 'sessions/email_validate', to: 'sessions#email_validate', as: 'email_validate'
    post 'sessions/validate_email', to: 'sessions#validate_email', as: 'validate_email'
    get 'feedback', to: 'sessions#feedback', as: 'feedback'
    post 'feedback_signup', to: 'sessions#feedback_signup', as: 'feedback_signup'
    
    post 'helpdesk', to: 'pages#helpdesk', as: 'contact_helpdesk'
    
    get 'close_page', to: 'pages#close_page'
    get 'contact', to: 'pages#contact'
    get 'mission', to: 'pages#what_we_do'
    get 'join_us', to: 'pages#join_us'
    get 'support_us', to: 'pages#support_us'
    get 'code_of_conduct', to: 'pages#code_of_conduct'
    get 'ethics', to: 'pages#ethics'
    get 'pb_tombstone', to: 'pages#pb_tombstone'
    get 'why_use', to: 'pages#why_use'
    get 'dda', to: 'pages#dda' # data deposit agreement
    get 'terms', to: 'pages#terms'
    get 'partner_terms', to: 'pages#terms_partner'
    get 'about', to: 'pages#who_we_are'
    get 'api', to: 'pages#api'
    get 'definitions', to: 'pages#definitions'
    get 'publication_policy', to: 'pages#publication_policy'
    get 'privacy', to: 'pages#privacy'
    get 'accessibility', to: 'pages#accessibility'
    get 'membership', to: 'pages#membership'
    get 'publishers', to: 'pages#fees_publisher'
    get 'institutions', to: 'pages#fees_institution'
    get 'fee_waiver', to: 'pages#fee_waiver'
    get 'sandbox', to: 'pages#sandbox' unless Rails.env.include?('production') 

    # redirect the urls with an encoded forward slash in the identifier to a URL that DataCite expects for matching their tracker
    # All our identifiers seem to have either /dryad or /FK2 or /[A-Z]\d in them, replaces the first occurrence of %2F with /
    get 'dataset/*id/linkset', to: 'landing#linkset', as: 'linkset', constraints: { id: /\S+/ }
    get 'dataset/*id', to: redirect{ |params| "/dataset/#{params[:id].sub('%2F', '/') }"}, status: 302,
        constraints: { id: /\S+\d%2F(dryad|FK2|[A-Z]\d)\S+/ }
    get 'dataset/*id', to: 'landing#show', as: 'show', constraints: { id: /\S+/ }
    get 'landing/citations/:identifier_id', to: 'landing#citations', as: 'show_citations'
    get '/404', to: 'pages#app_404', as: 'app_404'
    get 'landing/metrics/:identifier_id', to: 'landing#metrics', as: 'show_metrics'
    get 'test', to: 'pages#test'
    get 'ip_error', to: 'pages#ip_error'

    # user management
    get 'account', to: 'user_account#index', as: 'my_account'
    post 'account/edit', to: 'user_account#edit', as: 'edit_account'
    post 'account/api', to: 'user_account#api_application', as: 'get_api'
    post 'account/token', to: 'user_account#api_token', as: 'get_token'
    # admin user management
    get 'user_admin', to: 'user_admin#index' # main page for administering users
    # page for viewing a single user
    get 'user_admin/user_profile/:id', to: 'user_admin#user_profile', as: 'user_admin_profile'
    # admin editing user
    get 'user_admin/merge', to: 'user_admin#merge_popup', as: 'user_merge_popup'
    post 'user_admin/merge', to: 'user_admin#merge', as: 'user_admin_merge'
    get 'user_admin/:id/edit', to: 'user_admin#edit', as: 'user_edit'
    post 'user_admin/:id', to: 'user_admin#update', as: 'user_update'
    post 'user_admin/:id/api', to: 'user_admin#api_application', as: 'user_api'
    # admin tenant management
    get 'tenant_admin', to: 'tenant_admin#index'
    get 'tenant_admin/:id/edit', to: 'tenant_admin#edit', as: 'tenant_edit'
    post 'tenant_admin/:id', to: 'tenant_admin#update', as: 'tenant_update'
    get 'tenant_admin/new', to: 'tenant_admin#new', as: 'tenant_new'
    post 'tenant_admin', to: 'tenant_admin#create', as: 'tenant_create'
    # admin journal management
    get 'journal_admin', to: 'journal_admin#index'
    get 'journal_admin/:id/edit', to: 'journal_admin#edit', as: 'journal_edit'
    post 'journal_admin/:id', to: 'journal_admin#update', as: 'journal_update'
    get 'journal_admin/new', to: 'journal_admin#new', as: 'journal_new'
    post 'journal_admin', to: 'journal_admin#create', as: 'journal_create'
    # admin publisher management
    get 'publisher_admin', to: 'journal_organization_admin#index', as: 'publisher_admin'
    get 'publisher_admin/:id/edit', to: 'journal_organization_admin#edit', as: 'publisher_edit'
    post 'publisher_admin/:id', to: 'journal_organization_admin#update', as: 'publisher_update'
    get 'publisher_admin/new', to: 'journal_organization_admin#new', as: 'publisher_new'
    post 'publisher_admin', to: 'journal_organization_admin#create', as: 'publisher_create'

    # admin_dashboard
    match 'admin_dashboard', to: 'admin_dashboard#index', via: %i[get post]
    match 'admin_dashboard/results', to: 'admin_dashboard#results', via: %i[get post], as: 'admin_dashboard_results'
    match 'admin_dashboard/count', to: 'admin_dashboard#count', via: %i[get post], as: 'admin_dashboard_count'
    get 'admin_dashboard/:id/edit/:field', to: 'admin_dashboard#edit', as: 'admin_dash_edit'
    post 'admin_dashboard/:id', to: 'admin_dashboard#update', as: 'admin_dash_update'
    get 'admin_search', to: 'admin_dashboard#new_search', as: 'new_admin_search'
    match 'admin_search/:id', to: 'admin_dashboard#save_search', via: %i[put patch], as: 'save_admin_search'

    # saved_searches
    # get 'account/saved_searches/:type', to: 'saved_searches#index'
    post 'saved_search', to: 'saved_searches#create'
    get 'saved_search/:id', to: 'saved_searches#edit', as: 'saved_search_edit'
    match 'saved_search/:id', to: 'saved_searches#update', via: %i[put patch], as: 'update_saved_search'
    delete 'saved_search/:id', to: 'saved_searches#destroy', as: 'saved_search_delete'

    # activity log
    get 'ds_admin/:id', to: 'admin_datasets#index', as: 'activity_log'
    get 'ds_admin/:id/activity_log', to: 'admin_datasets#activity_log', as: 'activity'
    get 'ds_admin/:id/change_log', to: 'admin_datasets#change_log', as: 'change_log'
    get 'ds_admin/:id/file_log', to: 'admin_datasets#file_log', as: 'file_log'
    get 'ds_admin/:id/payment_log', to: 'admin_datasets#payment_log', as: 'payment_log'
    get 'ds_admin/:id/create_salesforce_case', to: 'admin_datasets#create_salesforce_case', as: 'create_salesforce_case'
    get 'ds_admin/:id/edit/:field', to: 'admin_datasets#popup', as: 'ds_admin_popup'
    post 'ds_admin/:id/notification_date', to: 'admin_datasets#notification_date', as: 'notification_date'    
    post 'ds_admin/:id/waive', to: 'admin_datasets#waiver_add', as: 'ds_admin_waiver'
    post 'ds_admin/:id/flag', to: 'admin_datasets#flag', as: 'ds_admin_flag'
    post 'ds_admin/:id/edit_submitter', to: 'admin_datasets#edit_submitter', as: 'ds_admin_edit_submitter'
    post 'ds_admin/:id/pub_dates', to: 'admin_datasets#pub_dates', as: 'ds_admin_pub_dates'
    post 'ds_admin/:id/issue', to: 'admin_datasets#create_issue', as: 'ds_admin_issue'
    delete 'ds_admin/:id', to: 'admin_datasets#destroy', as: 'ds_admin_destroy'
    

    # curation notes
    post 'curation_note/:id', to: 'curation_activity#curation_note', as: 'curation_note'
    post 'file_note/:id', to: 'curation_activity#file_note', as: 'file_note'
    get 'file_note/:resource_id', to: 'curation_activity#make_file_note'

    # admin report for dataset funders
    get 'ds_admin_funders', to: 'admin_dataset_funders#index', as: 'ds_admin_funders'

    # routing for submission queue controller
    get 'submission_queue', to: 'submission_queue#index'
    get 'submission_queue/refresh_table', to: 'submission_queue#refresh_table'
    get 'submission_queue/graceful_start', to: 'submission_queue#graceful_start', as: 'graceful_start'

    # routing for zenodo_queue
    get 'zenodo_queue', to: 'zenodo_queue#index', as: 'zenodo_queue'
    get 'zenodo_queue/item_details/:id', to: 'zenodo_queue#item_details', as: 'zenodo_queue_item_details'
    get 'zenodo_queue/identifier_details/:id', to: 'zenodo_queue#identifier_details', as: 'zenodo_queue_identifier_details'
    post 'zenodo_queue/resubmit_job', to: 'zenodo_queue#resubmit_job', as: 'zenodo_queue_resubmit_job'
    post 'zenodo_queue/set_errored', to: 'zenodo_queue#set_errored', as: 'zenodo_queue_set_errored'

    # Administrative Status Dashboard that displays statuses of external dependencies
    get 'status_dashboard', to: 'status_dashboard#show'

    # Publication updater page - Allows admins to accept/reject metadata changes from external sources like Crrossref
    get 'publication_updater', to: 'publication_updater#index'
    get 'publication_updater/log', to: 'publication_updater#log'
    put 'publication_updater/:id', to: 'publication_updater#update'
    delete 'publication_updater/:id', to: 'publication_updater#destroy'

    # Curation stats
    get 'curation_stats', to: 'curation_stats#index'

    # Journals
    get 'journals', to: 'journals#index'

    # GMail authentication page for journals
    get 'gmail_auth', to: 'gmail_auth#index'

    resource :pots, only: [:show]
  end

  # the ones below coming from new routing for blacklight
  #--------------------------------------------------------
  concern :searchable, Blacklight::Routes::Searchable.new
  resource :catalog, as: 'catalog', path: '/search', controller: 'catalog' do
    concerns :searchable
  end

  # get 'search', to: 'catalog#search', as: 'search'

  # this is kind of hacky, but it directs our search results to open links to the landing pages
  resources :solr_documents, only: [:show], path: '/dataset', controller: 'catalog'

  ############################# Discovery support ######################################

  get '/latest', to: 'latest#index', as: 'latest_index'

  # Endpoint for LinkOut
  get :discover, to: 'catalog#discover'

  ########################## StashDatacite support ######################################

  scope module: 'stash_datacite', path: '/stash_datacite' do
    get 'titles/new', to: 'titles#new'
    post 'titles/create', to: 'titles#create'
    patch 'titles/update', to: 'titles#update'

    get 'descriptions/:id', to: 'descriptions#show'
    get 'descriptions/new', to: 'descriptions#new'
    post 'descriptions/create', to: 'descriptions#create'
    patch 'descriptions/update', to: 'descriptions#update'

    get 'temporal_coverages/new', to: 'temporal_coverages#new'
    patch 'temporal_coverages/update', to: 'temporal_coverages#update'

    get 'authors/new', to: 'authors#new'
    post 'authors/create', to: 'authors#create'
    patch 'authors/update', to: 'authors#update'
    delete 'authors/:id/delete', to: 'authors#delete', as: 'authors_delete'
    patch 'authors/reorder', to: 'authors#reorder', as: 'authors_reorder'
    get 'authors/:id/invoice', to: 'authors#check_invoice'
    patch 'authors/invoice', to: 'authors#set_invoice'
    patch 'authors/invite', to: 'authors#invite'

    get 'contributors/new', to: 'contributors#new'
    get 'contributors/autocomplete', to: 'contributors#autocomplete'
    get 'contributors/award_details', to: 'contributors#award_details'
    post 'contributors/grouping', to: 'contributors#grouping'
    post 'contributors/create', to: 'contributors#create'
    patch 'contributors/update', to: 'contributors#update'
    patch 'contributors/reorder', to: 'contributors#reorder', as: 'contributors_reorder'
    delete 'contributors/:id/delete', to: 'contributors#delete', as: 'contributors_delete'

    get 'publications/new', to: 'publications#new'
    get 'publications/autocomplete', to: 'publications#autocomplete'
    get 'publications/automsid', to: 'publications#automsid'
    get 'publications/api_list', to: 'publications#api_list'
    get 'publications/issn/:id', to: 'publications#issn'
    post 'publications/create', to: 'publications#create'
    patch 'publications/update', to: 'publications#update'
    delete 'publications/:id/delete', to: 'publications#delete', as: 'publications_delete'
    post 'publications/autofill/:id', to: 'publications#autofill_data', as: 'publications_autofill_data'

    get 'resource_types/new', to: 'resource_types#new'
    post 'resource_types/create', to: 'resource_types#create'
    patch 'resource_types/update', to: 'resource_types#update'

    get 'subjects/new', to: 'subjects#new'
    get 'subjects/autocomplete', to: 'subjects#autocomplete'
    post 'subjects/create', to: 'subjects#create'
    delete 'subjects/:id/delete', to: 'subjects#delete', as: 'subjects_delete'
    get 'subjects/landing', to: 'subjects#landing', as: 'subjects_landing'

    # fos subjects are a special subject that is treated differently for the OECD Field of Science
    get 'fos_subjects', to: 'fos_subjects#index'
    patch 'fos_subjects/update', to: 'fos_subjects#update'

    get 'related_identifiers/new', to: 'related_identifiers#new'
    post 'related_identifiers/create', to: 'related_identifiers#create'
    patch 'related_identifiers/update', to: 'related_identifiers#update'
    delete 'related_identifiers/:id/delete', to: 'related_identifiers#delete', as: 'related_identifiers_delete'
    get 'related_identifiers/report', to: 'related_identifiers#report', as: 'related_identifiers_report'
    get 'related_identifiers/show', to: 'related_identifiers#show', as: 'related_identifiers_show'
    get 'related_identifiers/types', to: 'related_identifiers#types'

    get 'geolocation_places/new', to: 'geolocation_places#new'
    post 'geolocation_places/create', to: 'geolocation_places#create'
    delete 'geolocation_places/:id/delete', to: 'geolocation_places#delete', as: 'geolocation_places_delete'

    get 'geolocation_points/new', to: 'geolocation_points#new'
    post 'geolocation_points/create', to: 'geolocation_points#create'
    delete 'geolocation_points/:id/delete', to: 'geolocation_points#delete', as: 'geolocation_points_delete'

    get 'geolocation_boxes/new', to: 'geolocation_boxes#new'
    post 'geolocation_boxes/create', to: 'geolocation_boxes#create'
    delete 'geolocation_boxes/:id/delete', to: 'geolocation_boxes#delete', as: 'geolocation_boxes_delete'

    get 'affiliations/autocomplete', to: 'affiliations#autocomplete'
    get 'affiliations/new', to: 'affiliations#new'
    post 'affiliations/create', to: 'affiliations#create'
    delete 'affiliations/:id/delete', to: 'affiliations#delete', as: 'affiliations_delete'

    get 'licenses/details', to: 'licenses#details', as: 'license_details'

    # Actions through Leaflet Ajax posts
    # points
    get 'geolocation_points/index', to: 'geolocation_points#index'
    get 'geolocation_points/points_coordinates', to: 'geolocation_points#points_coordinates'
    post 'geolocation_points/map_coordinates', to: 'geolocation_points#map_coordinates'
    put 'geolocation_points/update_coordinates', to: 'geolocation_points#update_coordinates'
    delete 'geolocation_points/delete_coordinates', to: 'geolocation_points#delete'
    # bounding boxes
    get 'geolocation_boxes/boxes_coordinates', to: 'geolocation_boxes#boxes_coordinates'
    post 'geolocation_boxes/map_coordinates', to: 'geolocation_boxes#map_coordinates'
    # location names/places
    get 'geolocation_places/places_coordinates', to: 'geolocation_places#places_coordinates'
    post 'geolocation_places/map_coordinates', to: 'geolocation_places#map_coordinates'

    # get composite views or items that begin at the resource level
    get 'metadata_entry_pages/find_or_create', to: 'metadata_entry_pages#find_or_create', as: :datacite_metadata_entry_pages
    get 'metadata_entry_pages/:resource_id/files', to: 'metadata_entry_pages#find_files', as: 'find_files'
    get 'resources/review', to: 'resources#review'
    match 'resources/submission' => 'resources#submission', as: :resources_submission, via: :post
    get 'resources/show', to: 'resources#show'

    patch 'peer_review/toggle', to: 'peer_review#toggle', as: :peer_review
    patch 'peer_review/release', to: 'peer_review#release', as: :peer_review_release
  end

  scope module: 'help', path: 'help' do
    get '/', to: 'help', as: 'help'
    get '/contact', to: 'contact'
    get ':folder/:page', to: 'topic'
  end

  get :fee_calculator, to: 'fee_calculator#calculate_fee', format: :json
  get 'resource_fee_calculator/:id', to: 'fee_calculator#calculate_resource_fee', format: :json, as: :resource_fee_calculator

  resources :payments, only: [] do
    collection do
      post ':resource_id', to: 'payments#create'
      get :callback

      delete '/reset_payment/:identifier_id', to: 'payments#reset_payment', as: :reset_payment
    end
  end

  get :health_check, to: 'health#check'

  ########################## CEDAR Embeddable Editor ###############################

  post 'metadata_entry_pages/cedar_popup', to: 'metadata_entry_pages#cedar_popup', as: 'cedar_popup'

  # Redirect the calls for MaterialUI icons, since the embeddable editor doesn't know what path it was loaded from
  get '/metadata_entry_pages/MaterialIcons-Regular.woff', to: redirect('/MaterialIcons-Regular.woff')
  get '/metadata_entry_pages/MaterialIcons-Regular.woff2', to: redirect('/MaterialIcons-Regular.woff2')
  get '/metadata_entry_pages/MaterialIcons-Regular.ttf', to: redirect('/MaterialIcons-Regular.ttf')

  get '/cedar-config', to: 'cedar#json_config'
  post '/cedar-save', to: 'cedar#save'

  ########################## Redirects ######################################

  # Routing to redirect old Dryad URLs to their correct locations in this system
  get '/pages/faq', to: redirect('/requirements')
  get '/pages/jdap', to: redirect('docs/JointDataArchivingPolicy.pdf')
  get '/pages/membershipOverview', to: redirect('/join_us#our-membership')
  get '/stash/our_membership', to: redirect('/join_us#our-membership')
  get '/stash/our_community', to: redirect('/join_us#our-membership')
  get '/stash/our_governance', to: redirect('/about#our-board')
  get '/stash/our_staff', to: redirect('/about#our-staff')
  get '/stash/our_advisors', to: redirect('/about#our-advisors')
  get '/stash/our_platform', to: redirect('/mission#our-platform')
  get '/stash/our_mission', to: redirect('/mission')
  get '/stash/faq', to: redirect('/requirements')
  get '/pages/organization', to: redirect('/mission')
  get '/pages/policies', to: redirect('/terms')
  get 'terms/view', to: redirect('/terms')
  get '/pages/publicationBlackout', to: redirect('/pb_tombstone')
  get '/publicationBlackout', to: redirect('/pb_tombstone')
  get '/pages/searching', to: redirect('search')
  get '/themes/Dryad/images/:image', to: redirect('/images/%{image}')
  get '/themes/Dryad/images/dryadLogo.png', to: redirect('/images/logo_dryad.png')
  get '/themes/Mirage/*path', to: redirect('/')
  get '/repo/*path', to: redirect('/')
  get '/repo', to: redirect('/')
  get '/submit', to: redirect { |params, request| "/resources/new?#{request.params.to_query}" }
  get '/interested', to: redirect('/contact#get-involved')
  get '/stash/interested', to: redirect('/contact#get-involved')
  get '/stash/ds_admin', to: redirect('/admin_dashboard')

  get '/stash', to: redirect('/')
  get '/stash/*path', to: redirect { |params, req|
    query = req.query_string.present? ? "?#{req.query_string}" : ""
    "/#{params[:path]}#{query}"
  }, constraints: { path: /.*/ }

  # Help center redirects
  get '/requirements', to: redirect('/help/requirements/files')
  get '/costs', to: redirect('/help/requirements/costs')
  get '/reuse', to: redirect('/help/guides/reuse')
  get '/best_practices', to: redirect('/help/guides/best_practices')
  get '/submission_process', to: redirect('/help/submission_steps/submission')
  get '/data_check_guide', to: redirect('/help/guides/data_check_alerts')
  get '/process', to: redirect('/help/submission_steps/publication')
  get '/HumanSubjectsData.pdf', to: redirect('/help/guides/HumanSubjectsData.pdf')
  get '/EndangeredSpeciesData.pdf', to: redirect('/help/guides/EndangeredSpeciesData.pdf')
  get '/QuickstartGuideToDataSharing.pdf', to: redirect('/help/guides/QuickstartGuideToDataSharing.pdf')

  # Routing to redirect old Dryad landing pages to the correct location
  # Regex based on https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but a little more restrictive specific to old dryad
  # Dataset:            https://datadryad.org/resource/doi:10.5061/dryad.kq201
  # Version of Dataset: https://datadryad.org/resource/doi:10.5061/dryad.kq201.2
  get '/resource/:doi_prefix/:doi_suffix',
      constraints: { doi_prefix: /doi:10.\d{4,9}/i, doi_suffix: /[A-Z0-9]+\.[A-Z0-9]+/i },
      to: redirect{ |p, req| "/dataset/#{p[:doi_prefix]}/#{p[:doi_suffix]}" }
  # File within a Dataset:            https://datadryad.org/resource/doi:10.5061/dryad.kq201/3
  # Version of File within a Dataset: https://datadryad.org/resource/doi:10.5061/dryad.kq201/3.1
  # File within a Version:            https://datadryad.org/resource/doi:10.5061/dryad.kq201.2/3
  # Version of File within a Version: https://datadryad.org/resource/doi:10.5061/dryad.kq201.2/3.1
  get '/resource/:doi_prefix/:doi_suffix*file',
      constraints: { doi_prefix: /doi:10.\d{4,9}/i, doi_suffix: /[A-Z0-9]+\.[A-Z0-9]+/i },
      to: redirect{ |p, req| "/dataset/#{p[:doi_prefix]}/#{p[:doi_suffix]}" }
end
