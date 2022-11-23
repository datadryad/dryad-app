module Tasks
  module MigrationImport
    Dir.glob(File.expand_path('migration_import/*.rb', __dir__)).each(&method(:require))
  end
end
