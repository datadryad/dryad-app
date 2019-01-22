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
    status { 'Unsubmitted' }
    note { 'article was published' }
    keywords { 'foo bar' }
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
end
