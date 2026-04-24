# Usage: rails r script/create_dataset.rb <user_id>

include FactoryBot::Syntax::Methods
include Rails.application.routes.url_helpers
require Rails.root.join('spec/support/faker.rb')

user = StashEngine::User.find(ARGV[0])
ident = create(:identifier, import_info: 0)
resource = create(:resource, identifier_id: ident.id, current_editor_id: user.id, tenant_id: user.tenant_id, user: user, accepted_agreement: true)

create(:description, resource: resource, description_type: 'technicalinfo')
create(:description, resource: resource, description_type: 'hsi_statement', description: nil)
create(:description, resource: resource, description_type: 'abstract', description: 'Abstract')

puts "DOI: #{ident.identifier}"
puts "Identifier: #{ident.id}"
puts "Resource: #{resource.id} - #{resource.title}"
puts "URL: #{metadata_entry_pages_find_or_create_url(resource)}"
