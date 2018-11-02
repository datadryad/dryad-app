require_relative 'identifier_rake_functions'

desc 'Give resources missing a stash_engine_identifier one (run from main app, not engine)'
task fix_missing_stash_engine_identifiers: :environment do # loads rails environment
  IdentifierRakeFunctions.update_identifiers
end
