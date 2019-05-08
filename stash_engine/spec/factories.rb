# see for setting up factorybot https://medium.com/@lukepierotti/setting-up-rspec-and-factory-bot-3bb2153fb909

require 'spec_helper'

FactoryBot.define do
  factory(:user, class: StashEngine::User) do
    first_name { 'Juanita' }
    last_name { 'Collins' }
    email { 'juanita.collins@example.org' }
    tenant_id { 'exemplia' }
    role { 'user' }
    orcid { '1098-415-1212' }
    migration_token { 'xxxxxx' }
    old_dryad_email { 'lolinda@example.com' }
    eperson_id { 37 }
  end

  factory(:identifier, class: StashEngine::Identifier) do
    identifier { '10.1072/FK2something' }
    identifier_type { 'DOI' }
  end

  factory(:curation_activity, class: StashEngine::CurationActivity) do
    status { 'in_progress' }
    note { 'article was published' }
    keywords { 'foo bar' }

    factory(:curation_activity_no_callbacks) do
      before(:create) do |ca|
        # redefine these  methods so I can set this crap in peace without all the horror
        # https://stackoverflow.com/questions/8751175/skip-callbacks-on-factory-girl-and-rspec
        ca.define_singleton_method(:submit_to_datacite) {}
        ca.define_singleton_method(:update_solr) {}
        ca.define_singleton_method(:submit_to_stripe) {}
        ca.define_singleton_method(:email_author) {}
        ca.define_singleton_method(:email_orcid_invitations) {}
      end
    end
  end

  factory(:resource, class: StashEngine::Resource) do
    title { 'My test factory' }
    tenant_id { 'dryad' }
    skip_emails { true }
  end

  factory(:version, class: StashEngine::Version) do
    version { 1 }
    merritt_version { 1 }
  end

  factory(:resource_state, class: StashEngine::ResourceState) do
    resource_state { 'submitted' }
  end

  factory(:file_upload, class: StashEngine::FileUpload) do
    upload_file_name { 'Sidlauskas 2007 Data.xls' }
    upload_content_type { 'application/vnd.ms-excel' }
    upload_file_size { 124_664 }
    temp_file_path { '/apps/dryad/apps/ui/releases/20181115200056/uploads/1136/Sidlauskas 2007 Data.xls' }
  end

  factory(:internal_datum, class: StashEngine::InternalDatum) do
    data_type { 'publicationISSN' }
    value { '1352-3867' }
  end
end
