FactoryBot.define do
  factory(:user, class: StashEngine::User) do
    first_name { 'Juanita' }
    last_name { 'Collins' }
    email { 'juanita.collins@example.org' }
    tenant_id { 'exemplia' }
    role { 'user' }
    migration_token { 'xxxxxx' }
    old_dryad_email { 'lolinda@example.com' }
    eperson_id { 37 }
  end
end
