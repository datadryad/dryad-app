# frozen_string_literal: true

class AddShibbolethToExternalDependencies < ActiveRecord::Migration[8.0]
  def up
    StashEngine::ExternalDependency.create!({
      abbreviation: 'shibboleth',
      name: 'Shibboleth',
      description: 'Shibboleth login',
      documentation: 'Dryad uses Shibboleth to validate that users are affiliated with member institutions. ',
      internally_managed: true,
      status: 1
    })
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
